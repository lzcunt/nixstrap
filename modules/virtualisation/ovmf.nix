{ hostPkgs, pkgs, lib, ... }:
let
  inherit (lib) mkPackageOption;

  targetPkgs = import hostPkgs.path {
    localSystem = hostPkgs.stdenv.buildPlatform;
    crossSystem = "${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux";
    inherit (hostPkgs) config overlays;
  };
in
{
  options.virtualisation.ovmf = {
    package = mkPackageOption targetPkgs "OVMF" { };
  };
}
