{ lib, ... }:
{
  options.system = {
    build = lib.mkOption {
      default = { };
      description = ''
        Attribute set of derivations used to build artifacts.
      '';
      type = lib.types.submoduleWith {
        modules = [
          {
            freeformType = with lib.types; lazyAttrsOf (uniq unspecified);
          }
        ];
      };
    };

    boot.loader.id = lib.mkOption {
      internal = true;
      description = "ID string of the used bootloader.";
      type = lib.types.str;
    };
  };
}
