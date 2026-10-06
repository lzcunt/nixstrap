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
      inherit (archive) compression;
    }
  ) cfg;
}
