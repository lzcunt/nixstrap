{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.isoImage;
  limineCfg = config.boot.loader.limine;
in
{
  options = {
    isoImage.file = lib.mkOption {
      description = ''
        This option lists files to be copied to fixed locations in the
        generated ISO image.
      '';
      type = import ../lib/file-type.nix {
        inherit lib pkgs;
      } "isoImage.file";
    };

    isoImage.makeBiosBootable = lib.mkOption {
      default = pkgs.stdenv.hostPlatform.isx86;
      defaultText = lib.literalExpression "pkgs.stdenv.hostPlatform.isx86";
      type = lib.types.bool;
      description = ''
        Whether the ISO image should be a BIOS-bootable disk.
      '';
    };

    isoImage.makeEfiBootable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether the ISO image should be an EFI-bootable volume.
      '';
    };
  };
  config = lib.mkMerge [
    {
      # assertations = [
      #   {
      #     assertation = cfg.makeBiosBootable -> pkgs.stdenv.hostPlatform.isx86;
      #     message = "BIOS boot is only supported on x86-based architectures.";
      #   }
      # ];

      system.build.isoImage = pkgs.callPackage ../lib/make-iso9660-image.nix (
        {
          bootable = cfg.makeBiosBootable;
          bootImage =
            {
              limine = "boot/limine-bios-cd.bin";
            }
            .${config.system.boot.loader.id};
          contents = lib.attrValues cfg.file;
        }
        // lib.optionalAttrs cfg.makeEfiBootable {
          efiBootable = true;
          efiBootImage =
            {
              limine = "boot/limine-uefi-cd.bin";
            }
            .${config.system.boot.loader.id};
        }
      );
    }
    (lib.mkIf limineCfg.enable {
      isoImage.file."boot/limine.conf".source = limineCfg.config;
    })
    (lib.mkIf (limineCfg.enable && cfg.makeBiosBootable) {
      isoImage.file."boot/limine-bios-cd.bin".source =
        "${limineCfg.package}/share/limine/limine-bios-cd.bin";
      isoImage.file."boot/limine-bios.sys".source = "${limineCfg.package}/share/limine/limine-bios.sys";
    })
    (lib.mkIf (limineCfg.enable && cfg.makeEfiBootable) (
      let
        efiExec = "BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI";
      in
      {
        isoImage.file."boot/limine-uefi-cd.bin".source =
          limineCfg.package + "/share/limine/limine-uefi-cd.bin";
        isoImage.file."EFI/BOOT/${efiExec}".source = limineCfg.package + "/share/limine/${efiExec}";
      }
    ))
  ];
}
