{
  description = "Operating system & distribution bootstrapper";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    {
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
                inherit (hostPkgs) overlays;
              };
            };
        };
    };
}
