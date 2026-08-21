# Adapted from home-manager.
# Adapted from Nixpkgs.

{
  config,
  lib,
  pkgs,
  pkgsPath,
  ...
}:

with lib;

let

  isConfig = x: builtins.isAttrs x || builtins.isFunction x;

  optCall = f: x: if builtins.isFunction f then f x else f;

  mergeConfig =
    lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in
    lhs
    // rhs
    // optionalAttrs (lhs ? packageOverrides) {
      packageOverrides =
        pkgs:
        optCall lhs.packageOverrides pkgs // optCall (attrByPath [ "packageOverrides" ] ({ }) rhs) pkgs;
    }
    // optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides =
        pkgs:
        optCall lhs.perlPackageOverrides pkgs
        // optCall (attrByPath [ "perlPackageOverrides" ] ({ }) rhs) pkgs;
    };

  configType = mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check =
      x:
      let
        traceXIfNot = c: if c x then true else lib.traceSeqN 1 x false;
      in
      traceXIfNot isConfig;
    merge = args: foldr (def: mergeConfig def.value) { };
  };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = builtins.isFunction;
    merge = lib.mergeOneOption;
  };

  _pkgs = import pkgsPath (filterAttrs (n: v: v != null) config.nixpkgs);

in
{
  options.nixpkgs = {
    config = mkOption {
      default = null;
      example = {
        allowBroken = true;
      };
      type = types.nullOr configType;
      description = ''
        The configuration of the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to set
        package configuration options.

        If `null`, then configuration is taken from
        the fallback location, for example,
        {file}`~/.config/nixpkgs/config.nix`.
      '';
    };

    overlays = mkOption {
      default = null;
      example = literalExpression ''
        [
          (final: prev: {
            openssh = prev.openssh.override {
              hpnSupport = true;
              withKerberos = true;
              kerberos = final.libkrb5;
            };
          })
        ]
      '';
      type = types.nullOr (types.listOf overlayType);
      description = ''
        List of overlays to use with the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to
        override packages globally. This is a function that takes as
        an argument the *original* Nixpkgs. The
        first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.

        If `null`, then the overlays are taken from
        the fallback location, for example,
        {file}`~/.config/nixpkgs/overlays`.

        Like {var}`nixpkgs.config` this option only
        applies within the nixstrap configuration.
      '';
    };

    system = mkOption {
      type = types.str;
      example = "i686-linux";
      internal = true;
    };

    crossSystem = mkOption {
      type = lib.types.anything;
      example = literalExpression ''
        { config = "x86_64-elf"; }
      '';
      internal = true;
    };
  };

  config = {
    _module.args = {
      # We use a no-op override to make sure that the option can be merged without evaluating
      # `_pkgs`, see https://github.com/nix-community/home-manager/pull/993
      pkgs = mkOverride modules.defaultOverridePriority _pkgs;
    };
  };
}
