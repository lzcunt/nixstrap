{
  lib,
  stdenv,
  squashfs-tools,
  pkgsBuildHost,

  # The name of the resulting image file.
  name ? "squashfs.img",

  # The root directory of the squashfs filesystem is filled with the
  # closures of the Nix store paths listed here.
  storeContents ? [ ],

  # Pseudo files to be added to the squashfs image, as accepted by
  # the `-p` option of `mksquashfs`.
  pseudoFiles ? [ ],

  # Don't strip permissions from files, preserving the modes of the
  # files in the Nix store as-is.
  noStrip ? false,

  # Compression parameters, e.g. "zstd -Xcompression-level 6", or
  # null for none.
  comp ? "xz -Xdict-size 100%",
}:

let
  pseudoFilesArgs = lib.concatMapStrings (f: ''-p "${f}" '') pseudoFiles;
  compFlag = if comp == null then "-no-compression" else "-comp ${comp}";
in
stdenv.mkDerivation {
  inherit name;
  __structuredAttrs = true;

  # the image will be self-contained so we can drop references
  # to the closure that was used to build it
  unsafeDiscardReferences.out = true;

  nativeBuildInputs = [ squashfs-tools ];

  buildCommand =
    ''
      closureInfo=${pkgsBuildHost.closureInfo { rootPaths = storeContents; }}

      # Also include a manifest of the closures in a format suitable
      # for nix-store --load-db.
      cp $closureInfo/registration nix-path-registration
    ''
    + lib.optionalString stdenv.buildPlatform.is32bit ''
      # 64 cores on i686 does not work
      # fails with FATAL ERROR: mangle2:: xz compress failed with error code 5
      if ((NIX_BUILD_CORES > 48)); then
        NIX_BUILD_CORES=48
      fi
    ''
    + ''
      # Generate the squashfs image.
      # We have to set SOURCE_DATE_EPOCH to 0 here for reproducibility (https://github.com/NixOS/nixpkgs/issues/390696)
      SOURCE_DATE_EPOCH=0 mksquashfs nix-path-registration $(cat $closureInfo/store-paths) $out ${pseudoFilesArgs} \
        -no-hardlinks ${lib.optionalString noStrip "-no-strip"} -keep-as-directory -all-root -b 1048576 ${compFlag} \
        -processors $NIX_BUILD_CORES -root-mode 0755
    '';
}
