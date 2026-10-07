{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cpioArchive;

  suffixFor = compression:
    {
      gzip = "gz";
      zstd = "zst";
      xz = "xz";
    }
    .${compression};
in
{
  options.cpioArchive = lib.mkOption {
    default = { };
    description = ''
      Attribute set of CPIO archives to generate. Each archive is built
      from the files listed in its `file` option.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            file = lib.mkOption {
              default = { };
              description = ''
                This option lists files to be placed at fixed locations in
                the generated CPIO archive.
              '';
              type = import ../lib/file-type.nix {
                inherit lib pkgs;
              } "cpioArchive.${name}.file";
            };

            compression = lib.mkOption {
              default = null;
              type = lib.types.nullOr (
                lib.types.enum [
                  "gzip"
                  "zstd"
                  "xz"
                ]
              );
              description = ''
                The compression to apply to the generated archive, or
                `null` for none.
              '';
            };

            closurePaths = lib.mkOption {
              default = [ ];
              type = lib.types.listOf (
                lib.types.oneOf [
                  lib.types.package
                  lib.types.path
                  lib.types.singleLineStr
                ]
              );
              description = ''
                Store paths whose full runtime closure is grafted into
                the archive at their original `nix/store/...` locations,
                in addition to the files listed in `file`.
              '';
            };
          };
        }
      )
    );
  };

  config.system.build.cpioArchive = lib.mapAttrs (name: archive:
    pkgs.callPackage ../lib/make-cpio-archive.nix {
      name =
        "${name}.cpio"
        + lib.optionalString (archive.compression != null) ".${suffixFor archive.compression}";
      contents = lib.filter (file: file.enable) (lib.attrValues archive.file);
      inherit (archive) compression closurePaths;
    }
  ) cfg;
}
