# Adapted from home-manager.
{ lib, pkgs }:
opt:
let
  strings = import ./strings.nix { inherit lib; };
in
lib.types.attrsOf (
  lib.types.submodule (
    { name, config, ... }:
    let
      fromText = pkgs.writeTextFile {
        inherit (config) text;
        # TODO: executable = config.executable == true;
        name = strings.storeFileName name;
      };

      fromSymlink = pkgs.runCommand (strings.storeFileName name) { } ''
        ln -s -- ${lib.escapeShellArg config.symlink} "$out"
      '';
    in
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
            or [](#opt-${opt}._name_.symlink)
            must be set.
          '';
        };

        source = lib.mkOption {
          type = lib.types.path;
          apply =
            src:
            let
              conflict =
                if config.text != null && config.symlink != null then
                  "`text` and `symlink`"
                else if config.symlink != null && toString src != toString fromSymlink then
                  "`source` and `symlink`"
                else
                  null;
            in
            lib.throwIf (conflict != null) "${opt}: entry '${name}' must not set both ${conflict}" src;
          description = ''
            Path of the source file or directory. If
            [](#opt-${opt}._name_.text)
            is non-null then this option will automatically point to a file
            containing that text, and if
            [](#opt-${opt}._name_.symlink)
            is non-null then it will automatically point to a symbolic link
            to that path.
          '';
        };

        symlink = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Path of the symbolic link to generate at
            [](#opt-${opt}._name_.target),
            either absolute or relative to the link's location. Mutually
            exclusive with [](#opt-${opt}._name_.text) and an explicitly set
            [](#opt-${opt}._name_.source).
            The link's target is not followed, so it may dangle unless it is
            part of the generated file system itself.
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
        source = lib.mkIf (config.text != null || config.symlink != null) (
          lib.mkDefault (if config.symlink != null then fromSymlink else fromText)
        );
      };
    }
  )
)
