# Adapted from NixOS.
{ lib, ... }:

let
  addCheckDesc =
    desc: elemType: check:
    lib.types.addCheck elemType check // { description = "${elemType.description} (with check: ${desc})"; };

  isNonEmpty = s: (builtins.match "[ \t\n]*" s) == null;
  nonEmptyStr = addCheckDesc "non-empty" lib.types.str isNonEmpty;
  nonEmptyWithoutTrailingSlash = addCheckDesc "non-empty without trailing slash" lib.types.str (
    s: isNonEmpty s && (builtins.match ".+/" s) == null
  );

  specialFSTypes = [
    "proc"
    "sysfs"
    "tmpfs"
    "ramfs"
    "devtmpfs"
    "devpts"
  ];

  fileSystemOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "the filesystem mount" // {
          default = true;
        };

        mountPoint = lib.mkOption {
          example = "/mnt/usb";
          type = nonEmptyWithoutTrailingSlash;
          default = name;
          description = "Location where the file system will be mounted.";
        };

        device = lib.mkOption {
          default = null;
          example = "/dev/sda";
          type = lib.types.nullOr nonEmptyStr;
          description = ''
            The device as passed to `mount`.

            This can be any of:

            - a filename of a block special device such as `/dev/sdc3`
            - a tag such as `UUID=fdd68895-c307-4549-8c9c-90e44c71f5b7`
            - (for bind mounts only) the source path
            - something else depending on the {option}`fsType`. For example, `nfs` device may look like `knuth.cwi.nl:/dir`
          '';
        };

        fsType = lib.mkOption {
          example = "ext3";
          type = nonEmptyStr;
          description = "Type of the file system.";
        };

        options = lib.mkOption {
          default = [ "defaults" ];
          example = [ "data=journal" ];
          description = ''
            Options used to mount the file system.

            This is called `options` in {manpage}`mount(8)` and `fs_mntops` in {manpage}`fstab(5)`

            Some options that can be used for all mounts are documented in {manpage}`mount(8)` under `FILESYSTEM-INDEPENDENT MOUNT OPTIONS`.

            Options that systemd understands are documented in {manpage}`systemd.mount(5)` under `FSTAB`.

            Each filesystem supports additional options, see the docs for that filesystem.
          '';
          type = lib.types.nonEmptyListOf nonEmptyStr;
        };

        depends = lib.mkOption {
          default = [ ];
          example = [ "/persist" ];
          type = lib.types.listOf nonEmptyWithoutTrailingSlash;
          description = ''
            List of paths that should be mounted before this one. This filesystem's
            {option}`device` and {option}`mountPoint` are always
            checked and do not need to be included explicitly. If a path is added
            to this list, any other filesystem whose mount point is a parent of
            the path will be mounted before this filesystem. The paths do not need
            to actually be the {option}`mountPoint` of some other filesystem.

            This is useful for mounts which require keys and/or configuration files residing on another filesystem.
          '';
        };

      };

      config = {
        device = lib.mkIf (lib.elem config.fsType specialFSTypes) (lib.mkDefault config.fsType);
      };
    };
in
{
  options.fileSystems = lib.mkOption {
    default = { };
    example = lib.literalExpression ''
      {
        "/".device = "/dev/hda1";
        "/data" = {
          device = "/dev/hda2";
          fsType = "ext3";
          options = [ "data=journal" ];
        };
        "/bigdisk".label = "bigdisk";
      }
    '';
    type = lib.types.attrsOf (lib.types.submodule fileSystemOpts);
    apply = lib.filterAttrs (_: fs: fs.enable);
    description = ''
      The file systems to be mounted.  It must include an entry for
      the root directory (`mountPoint = "/"`).  Each
      entry in the list is an attribute set with the following fields:
      `mountPoint`, `device`,
      `fsType` (a file system type recognised by
      {command}`mount`), and `options`
      (the mount options passed to {command}`mount` using the
      {option}`-o` flag; defaults to `[ "defaults" ]`).
    '';
  };
}
