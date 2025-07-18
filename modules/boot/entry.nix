{ lib, ... }:
let
  # FIXME: assertations for protocol-specific and leaf/branch-specific options
  entryType = lib.types.submodule (
    { name, config, ... }:
    {
      options = {
        title = lib.mkOption {
          type = lib.types.str;
          defaultText = lib.literalExpression "name";
          description = ''
            The title of the entry. May be set for both branch and leaf entries.
          '';
        };

        description = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            An optional string that describes the entry. May be set for both
            branch and leaf entries.

            Limine will display this on the menu when the entry is selected.
          '';
        };

        child = lib.mkOption {
          type = lib.types.attrsOf entryType;
          default = { };
          description = ''
            Sub-entries that will be used to generate the configuration needed for
            the enabled bootloader. May only be set for branch entries.
          '';
        };

        expanded = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            If set, the branch entry will be expanded and won't show up as
            collapsed in the menu. May only be set for branch entries.
          '';
        };

        protocol = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              # "bios"
              # "efi"
              "limine"
              "linux"
              "multiboot"
              "multiboot1"
              "multiboot2"
            ]
          );
          default = null;
          description = ''
            The boot protocol that will be used to boot this entry. May only be
            set for leaf entries.
          '';
        };

        cmdline = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            The command line string to be passed to the kernel/executable. May be
            omitted. May only be set for leaf entries.
          '';
        };

        # FIXME: this shouldn't be bootloader-specific.
        kernelPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            The path of the kernel. Must be set for leaf entries with one of the
            following protocols: `limine`, `linux`, `multiboot`, `multiboot1`,
            `multiboot2`. Must not be set for branch entries or leaf entries with
            other protocols.

            The format of the path string is bootloader-specific.
          '';
        };

        modulePaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Paths to modules (such as initramfs) that should be passed to the kernel
          '';
        };

        # TODO: Limine protocol-specific keys
        kaslr = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            For relocatable kernels, whether to perform kernel address space
            layout randomisation. KASLR is enabled by default.

            Only supported on entries using the limine protocol.
          '';
        };
        # TODO: Linux protocol-specific keys

        mkLimineConfig = lib.mkOption {
          internal = true;
          readOnly = true;
          default = acc: ''
            ${acc}${if config.expanded then "+" else ""}${config.title}
            ${if config.description != null then "comment: ${config.description}" else ""}
            ${if config.protocol != null then "protocol: ${config.protocol}" else ""}
            ${if config.kernelPath != "" then "kernel_path: ${config.kernelPath}" else ""}
            ${lib.concatStrings (map (modulePath: "module_path: ${modulePath}") config.modulePaths)}
            ${if config.cmdline != "" then "cmdline: ${config.cmdline}" else ""}
            ${if config.kaslr != true then "kaslr: no" else ""}
            ${lib.concatStrings (map (entry: entry.mkLimineConfig (acc + "/")) (lib.attrValues config.child))}
          '';
        };

        limineConfig = lib.mkOption {
          type = lib.types.str;
          internal = true;
          readOnly = true;
          default = config.mkLimineConfig "/";
        };
      };

      config = {
        title = lib.mkDefault name;
      };
    }
  );
in
{
  options.boot.entry = lib.mkOption {
    type = lib.types.attrsOf entryType;
    default = { };
    description = ''
      Boot entries that will be used to generate the configuration needed for
      the enabled bootloader.
    '';
  };
}
