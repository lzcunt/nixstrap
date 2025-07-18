{ lib, ... }:
{
  imports = [
    ./limine.nix
  ];

  options.boot.loader = {
    timeout = lib.mkOption {
      default = 5;
      description = ''
        Timeout (in seconds) until loader boots the default menu item. Use null
        if the loader menu should be displayed indefinitely.
      '';
      type = lib.types.nullOr lib.types.int;
    };
  };
}
