{ lib, ... }:

with lib;

{
  options.system = {
    build = mkOption {
      default = { };
      description = ''
        Attribute set of derivations used to build artifacts.
      '';
      type = types.submoduleWith {
        modules = [
          {
            freeformType = with types; lazyAttrsOf (uniq unspecified);
          }
        ];
      };
    };

    label = mkOption {
      default = null;
      description = "Label of the resulting distribution";
      type = types.nullOr types.str;
    };

    boot.loader.id = mkOption {
      internal = true;
      description = "ID string of the used bootloader.";
      type = types.str;
    };
  };
}
