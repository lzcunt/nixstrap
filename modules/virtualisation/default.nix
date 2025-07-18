{ config, lib, hostPkgs, ... }:
let
  inherit (lib) types mkOption;
  cfg = config.virtualisation;
in
{
  imports = [
    ./qemu.nix
    ./ovmf.nix
  ];

  options.virtualisation = {
    cores = mkOption {
      type = types.ints.positive;
      default = 1;
      description = ''
        Specify the number of cores the guest is permitted to use.
        The number can be higher than the available cores on the
        host system.
      '';
    };

    memorySize = mkOption {
      type = types.ints.positive;
      default = 1024;
      description = ''
        The memory size in megabytes of the virtual machine.
      '';
    };
  };
}
