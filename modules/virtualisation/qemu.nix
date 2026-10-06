{
  config,
  lib,
  pkgs,
  hostPkgs,
  ...
}:
let
  inherit (lib) types mkPackageOption;

  qemu-common = import ../../lib/qemu-common.nix { inherit lib pkgs; };

  cfg = config.virtualisation.qemu;

  qemu = cfg.package;
  ovmf = config.virtualisation.ovmf.package;
in
{
  options.virtualisation.qemu = {
    package = mkPackageOption hostPkgs "qemu" { };
  };

  config = {
    system.build.qemuRunner = hostPkgs.writeScript "run-qemu" ''
      #!${hostPkgs.runtimeShell}
      exec ${qemu-common.qemuBinary qemu} \
        -m ${toString config.virtualisation.memorySize} \
        -smp ${toString config.virtualisation.cores} \
        -cdrom ${config.system.build.isoImage} \
        -drive if=pflash,format=raw,file=${ovmf.firmware},unit=0,readonly=on \
        -device qemu-xhci \
        -device usb-kbd \
        ${lib.optionalString (!pkgs.stdenv.hostPlatform.isx86) "-device ramfb"} \
        -serial mon:stdio \
        "$@"
    '';
  };
}
