# Adapted from home-manager.
{ lib, pkgs }:
opt:
let
  strings = import ./strings.nix { inherit lib; };
in
lib.types.attrsOf (
  lib.types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether this file should be generated. This option allows specific
            files to be disabled.
          '';
        };

        target = lib.mkOption {
          type = lib.types.str;
          apply = p: if lib.hasPrefix "/" p then lib.removePrefix "/" p else p;
          defaultText = lib.literalExpression "name";
          description = "Path to target file.";
        };

        text = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.lines;
          description = ''
            Text of the file. If this option is null then
            [](#opt-${opt}._name_.source)
            must be set.
          '';
        };

        source = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path of the source file or directory. If
            [](#opt-${opt}._name_.text)
            is non-null then this option will automatically point to a file
            containing that text.
          '';
        };

        # TODO
        # executable = lib.mkOption {
        #   type = lib.types.nullOr lib.types.bool;
        #   default = null;
        #   description = ''
        #     Set the execute bit. If `null`, defaults to the mode
        #     of the {var}`source` file or to `false`
        #     for files created through the {var}`text` option.
        #   '';
        # };
      };

      config = {
        target = lib.mkDefault name;
        source = lib.mkIf (config.text != null) (
          lib.mkDefault (
            pkgs.writeTextFile {
              inherit (config) text;
              # TODO: executable = config.executable == true;
              name = strings.storeFileName name;
            }
          )
        );
      };
    }
  )
)
