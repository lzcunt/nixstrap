{ pkgs, lib, ... }:
let
  inherit (lib) mkPackageOption;
in
{
  options.virtualisation.ovmf = {
    package = mkPackageOption pkgs "OVMF" { };
  };
}
