{ hostPkgs, pkgs, lib, ... }:
let
  inherit (lib) mkPackageOption;

  targetPkgs = import hostPkgs.path {
    localSystem = hostPkgs.stdenv.buildPlatform;
    crossSystem = pkgs.stdenv.hostPlatform;
    inherit (hostPkgs) config overlays;
  };
in
{
  options.virtualisation.ovmf = {
    package = mkPackageOption targetPkgs "OVMF" { };
  };
}
