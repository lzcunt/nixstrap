{
  config,
  lib,
  pkgs,
  hostPkgs,
  ...
}:
let
  cfg = config.boot.loader.limine;
in
{
  options.boot.loader.limine = {
    enable = lib.mkEnableOption "the limine bootloader";

    package = lib.mkOption {
      default = hostPkgs.limine.override {
        buildCDs = true;
        targets = [ pkgs.stdenv.hostPlatform.parsed.cpu.name ];
      };
      type = lib.types.package;
    };

    config = lib.mkOption {
      description = ''
        Path to the `limine.conf` source file. If unset, it is generated
        automatically from `config.boot.entry`.
      '';
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    system.boot.loader.id = "limine";

    boot.loader.limine.config = lib.mkDefault (
      pkgs.writeTextFile {
        name = "limine.conf";
        text = ''
          timeout: ${if config.boot.loader.timeout != null then toString config.boot.loader.timeout else "no"}
          ${lib.concatStrings (map (entry: entry.limineConfig) (lib.attrValues config.boot.entry))}
        '';
      }
    );
  };
}
