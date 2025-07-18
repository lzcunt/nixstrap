# Adapted from NixOS.
# QEMU-related utilities shared between various Nix expressions.
{ lib, pkgs }:

let
  zeroPad =
    n:
    lib.optionalString (n < 16) "0"
    + (if n > 255 then throw "Can't have more than 255 nets or nodes!" else lib.toHexString n);
in

rec {
  qemuNicMac = net: machine: "52:54:00:12:${zeroPad net}:${zeroPad machine}";

  qemuNICFlags = nic: net: machine: [
    "-device virtio-net-pci,netdev=vlan${toString nic},mac=${qemuNicMac net machine}"
    ''-netdev vde,id=vlan${toString nic},sock="$QEMU_VDE_SOCKET_${toString net}"''
  ];

  qemuSerialDevice =
    if with pkgs.stdenv.hostPlatform; isx86 || isLoongArch64 || isMips64 || isRiscV then
      "ttyS0"
    else if (with pkgs.stdenv.hostPlatform; isAarch || isPower) then
      "ttyAMA0"
    else
      throw "Unknown QEMU serial device for system '${pkgs.stdenv.hostPlatform.system}'";

  qemuBinary =
    qemuPkg:
    let
      hostStdenv = qemuPkg.stdenv;
      guestCpu = hostStdenv.hostPlatform.parsed.cpu.name;
      qemuUseKvm =
        hostStdenv.hostPlatform.qemuArch == pkgs.stdenv.hostPlatform.qemuArch
        && hostStdenv.hostPlatform.isLinux;

      accelFlags = if qemuUseKvm then "accel=kvm:tcg" else "accel=tcg";
      guests = {
        x86_64 = "${qemuPkg}/bin/qemu-system-x86_64 -machine ${accelFlags} -cpu max";
        armv7l = "${qemuPkg}/bin/qemu-system-arm -machine virt,${accelFlags} -cpu max";
        aarch64 = "${qemuPkg}/bin/qemu-system-aarch64 -machine virt,gic-version=max,${accelFlags} -cpu max";
        powerpc64le = "${qemuPkg}/bin/qemu-system-ppc64 -machine powernv";
        powerpc64 = "${qemuPkg}/bin/qemu-system-ppc64 -machine powernv";
        riscv32 = "${qemuPkg}/bin/qemu-system-riscv32 -machine virt";
        riscv64 = "${qemuPkg}/bin/qemu-system-riscv64 -machine virt";
      };
    in
    guests.${guestCpu} or (throw "Unsupported guest CPU architecture '${guestCpu}' for QEMU binary");
}
