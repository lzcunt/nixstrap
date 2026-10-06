# Remove leading and trailing slashes from a path
stripSlash() {
    res="$1"
    while test "${res:0:1}" = /; do res=${res:1}; done
    while test "${res:0:2}" = ./; do res=${res:2}; done
    while test "${#res}" -gt 1 && test "${res: -1}" = /; do res=${res:0:${#res}-1}; done
}

mkdir root

# Stage the individual files at their target paths.
for ((i = 0; i < ${#targets[@]}; i++)); do
    stripSlash "${targets[$i]}"
    target="$res"

    if test -z "$target"; then
        echo "empty target for source '${sources[$i]}'" >&2
        exit 1
    fi

    case "/$target/" in
        */../*)
            echo "target '$target' must not contain '..'" >&2
            exit 1
            ;;
    esac

    if test -e "root/$target" || test -L "root/$target"; then
        echo "duplicate target '$target' in archive contents" >&2
        exit 1
    fi

    mkdir -p "$(dirname "root/$target")"
    cp -R --preserve=mode,timestamps,links "${sources[$i]}" "root/$target"
done

# Normalise timestamps and perms
find root -exec touch -h -d "@${SOURCE_DATE_EPOCH:-0}" {} +
find root \( -type f -o -type d \) -exec chmod u+rwX {} +

(
    cd root
    find . -print0 | LC_ALL=C sort -z | cpio --null -o \
        -H "$format" --reproducible --owner="$owner" --quiet
) > archive.cpio

case "${compression-}" in
    "")
        mv archive.cpio "$out"
        ;;
    gzip)
        gzip -n -c archive.cpio > "$out"
        ;;
    zstd)
        zstd -q -c archive.cpio > "$out"
        ;;
    xz)
        xz -c archive.cpio > "$out"
        ;;
    *)
        echo "unsupported compression '${compression-}'" >&2
        exit 1
        ;;
esac
