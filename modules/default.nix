{
  configuration,
  hostPkgs,
  extraSpecialArgs ? { },
  _nixstrapInputs ? { },
}:
let
  inherit (hostPkgs) lib;
in
lib.evalModules {
  modules = [
    (
      { ... }:
      {
        _module.args.pkgsPath = lib.mkDefault hostPkgs.path;
        _module.args.hostPkgs = lib.mkDefault hostPkgs;
        nixpkgs.crossSystem = lib.mkDefault hostPkgs.stdenv.hostPlatform;
        nixpkgs.system = lib.mkDefault hostPkgs.stdenv.hostPlatform.system;
      }
    )
    configuration
    ./boot
    ./fileSystems.nix
    ./virtualisation
    ./isoImage.nix
    ./cpioArchive.nix
    ./nixpkgs.nix
    ./system.nix
  ];
  specialArgs = {
    inherit _nixstrapInputs;
  } // extraSpecialArgs;
}
