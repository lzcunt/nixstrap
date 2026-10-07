{
  lib,
  stdenv,
  cpio,
  gzip,
  zstd,
  xz,
  pkgsBuildHost,

  # The name of the resulting derivation (and thus the archive file).
  name ? "archive.cpio",

  # The files and directories to be placed in the archive.
  # This is a list of attribute sets {source, target} where `source'
  # is the file system object (regular file, directory or symlink) to be
  # grafted in the archive at path `target'.
  contents,

  # Store paths whose full runtime closure is grafted into the archive
  # at its original store paths (nix/store/...), in addition to `contents'.
  closurePaths ? [ ],

  # The cpio archive format (one of the formats accepted by `cpio -H').
  format ? "newc",

  # The owner of all archive members, as `USER:GROUP' for `cpio --owner'.
  owner ? "0:0",

  # The compression to apply to the archive, or null for none.
  compression ? null,
}:

assert compression == null || lib.elem compression [
  "gzip"
  "zstd"
  "xz"
];

let
  compressors = {
    inherit gzip zstd xz;
  };

  closure = if closurePaths == [ ] then "" else (pkgsBuildHost.closureInfo { rootPaths = closurePaths; }).outPath;
in
stdenv.mkDerivation {
  inherit
    name
    format
    owner
    closure
    ;

  compression = if compression == null then "" else compression;

  __structuredAttrs = true;

  buildCommandPath = ./make-cpio-archive.sh;
  nativeBuildInputs = [ cpio ] ++ lib.optionals (compression != null) [ compressors.${compression} ];

  sources = map (x: x.source) contents;
  targets = map (x: x.target) contents;
}
