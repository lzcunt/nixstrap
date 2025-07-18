{ lib, ... }:
{
  imports = [
  ];

  options.initrd = {
    path = lib.mkOption {
      description = ''
        Path to the initrd file. If unset, it is generated automatically.
      '';
      type = lib.types.path;
    };
  };
}
