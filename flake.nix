{
  description = "Operating system & distribution bootstrapper";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      overlay = final: prev: {
        # Builds a squashfs image from the closures of `storeContents`.
        # Usage: `pkgs.makeSquashfs { storeContents = [ ... ]; }`
        makeSquashfs = args: final.callPackage ./lib/make-squashfs.nix args;
      };
    in
    {
      overlays.default = overlay;

      lib.nixstrapConfiguration =
        {
          modules ? [ ],
          hostPkgs ? nixpkgs.legacyPackages.x86_64-linux,
          extraSpecialArgs ? { },
        }:
        import ./modules {
          inherit
            hostPkgs
            extraSpecialArgs
            ;
          configuration =
            { ... }:
            {
              imports = modules;
              nixpkgs = {
                config = nixpkgs.lib.mkDefault hostPkgs.config;
                overlays = hostPkgs.overlays ++ [ overlay ];
              };
            };
        };
    };
}
