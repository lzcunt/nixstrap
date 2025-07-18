{
  stdenv,
  xorriso,

  # The file name of the resulting ISO image.
  isoName ? "cd.iso",

  # The files and directories to be placed in the ISO file system.
  # This is a list of attribute sets {source, target} where `source'
  # is the file system object (regular file or directory) to be
  # grafted in the file system at path `target'.
  contents,

  # Whether this should be an El-Torito bootable CD.
  bootable ? false,

  # Whether this should be an efi-bootable El-Torito CD.
  efiBootable ? false,

  # Whether this should be an hybrid CD (bootable from USB as well as CD).
  usbBootable ? false,

  # The path (in the ISO file system) of the boot image.
  bootImage ? "",

  # The path (in the ISO file system) of the efi boot image.
  efiBootImage ? "",

  # The path (outside the ISO file system) of the isohybrid-mbr image.
  isohybridMbrImage ? "",
}:

assert bootable -> bootImage != "";
assert efiBootable -> efiBootImage != "";
assert usbBootable -> isohybridMbrImage != "";

stdenv.mkDerivation {
  name = isoName;
  __structuredAttrs = true;

  buildCommandPath = ./make-iso9660-image.sh;
  nativeBuildInputs = [
    xorriso
  ];

  inherit
    isoName
    bootable
    bootImage
    efiBootable
    efiBootImage
    isohybridMbrImage
    usbBootable
    ;

  sources = map (x: x.source) contents;
  targets = map (x: x.target) contents;
}
