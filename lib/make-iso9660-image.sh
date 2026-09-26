# Remove the initial slash from a path, since genisofs likes it that way.
stripSlash() {
    res="$1"
    if test "${res:0:1}" = /; then res=${res:1}; fi
}

# Escape potential equal signs (=) with backslash (\=)
escapeEquals() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/=/\\=/g'
}

# Queues an file/directory to be placed on the ISO.
# An entry consists of a local source path (2) and
# a destination path on the ISO (1).
addPath() {
    target="$1"
    source="$2"
    echo "$(escapeEquals "$target")=$(escapeEquals "$source")" >> pathlist
}

stripSlash "$bootImage"; bootImage="$res"

if test -n "$bootable"; then
  # The -boot-info-table option modifies the $bootImage file, so
  # find it in `contents' and make a copy of it (since the original
  # is read-only in the Nix store...).
  for ((i = 0; i < ${#targets[@]}; i++)); do
    stripSlash "${targets[$i]}"
    if test "$res" = "$bootImage"; then
      echo "copying the boot image ${sources[$i]}"
      cp "${sources[$i]}" boot.img
      chmod u+w boot.img
      sources[$i]=boot.img
    fi
  done

  isoBootFlags="-eltorito-boot ${bootImage}
                -eltorito-catalog .boot.cat
                -no-emul-boot -boot-load-size 4 -boot-info-table"
fi

if test -n "$usbBootable"; then
  usbBootFlags="-isohybrid-mbr ${isohybridMbrImage}"
fi

if test -n "$efiBootable"; then
  # -append_partition needs the EFI boot image as a file outside the ISO
  # file system, so find its source path in `contents'.
  stripSlash "$efiBootImage"
  efiBootImageIso="$res"
  efiBootImageDisk=""
  for ((i = 0; i < ${#targets[@]}; i++)); do
    stripSlash "${targets[$i]}"
    if test "$res" = "$efiBootImageIso"; then
      efiBootImageDisk="${sources[$i]}"
      break
    fi
  done

  if test -z "$efiBootImageDisk"; then
    echo "efiBootImage '$efiBootImage' is not among the ISO contents" >&2
    exit 1
  fi

  # Appending the EFI boot image as a partition gives the ISO a GPT with an
  # EFI system partition entry (and a protective MBR), so that firmware and
  # Limine can match the boot device handle with a volume.
  efiBootFlags="-append_partition 2 0xef $efiBootImageDisk
                -eltorito-alt-boot
                -e --interval:appended_partition_2:all::
                -no-emul-boot
                -appended_part_as_gpt
                -isohybrid-gpt-basdat"
fi

touch pathlist

# Add the individual files.
for ((i = 0; i < ${#targets[@]}; i++)); do
    stripSlash "${targets[$i]}"
    addPath "$res" "${sources[$i]}"
done

mkdir -p $out/iso

xorriso="xorriso
  -volume_date all_file_dates =$SOURCE_DATE_EPOCH
  -as mkisofs
  -R -r -J
  -iso-level 3
  -graft-points
  -full-iso9660-filenames
  ${isoBootFlags}
  ${usbBootFlags}
  ${efiBootFlags}
  -path-list pathlist
"

$xorriso -output $out/iso/$isoName
