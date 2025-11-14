{
  description = "A flake providing an up-to-date package for zed-editor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        withSystem,
        moduleWithSystem,
        flake-parts-lib,
        ...
      }:
      {
        systems = with nixpkgs.lib.platforms; linux ++ darwin;

        perSystem =
          {
            system,
            pkgs,
            self',
            inputs',
            ...
          }:
          {
            packages = {
              zed-editor = pkgs.callPackage ./packages/zed-editor { };
              zed-editor-fhs = self'.packages.zed-editor.passthru.fhs;

              zed-editor-preview = pkgs.callPackage ./packages/zed-editor-preview { };
              zed-editor-preview-fhs = self'.packages.zed-editor-preview.passthru.fhs;

              zed-editor-bin = pkgs.callPackage ./packages/zed-editor-bin { };
              zed-editor-bin-fhs = self'.packages.zed-editor-bin.passthru.fhs;

              zed-editor-preview-bin = pkgs.callPackage ./packages/zed-editor-preview-bin { };
              zed-editor-preview-bin-fhs = self'.packages.zed-editor-preview-bin.passthru.fhs;

              default = self'.packages.zed-editor;
            };

            apps = {
              zed-editor.program = "${self'.packages.zed-editor}/bin/zeditor";
              zed-editor-fhs.program = "${self'.packages.zed-editor-fhs}/bin/zeditor";
              zed-editor-preview.program = "${self'.packages.zed-editor-preview}/bin/zeditor";
              zed-editor-preview-fhs.program = "${self'.packages.zed-editor-preview-fhs}/bin/zeditor";
              zed-editor-bin.program = "${self'.packages.zed-editor-bin}/bin/zeditor";
              zed-editor-bin-fhs.program = "${self'.packages.zed-editor-bin-fhs}/bin/zeditor";
              zed-editor-preview-bin.program = "${self'.packages.zed-editor-preview-bin}/bin/zeditor";
              zed-editor-preview-bin-fhs.program = "${self'.packages.zed-editor-preview-bin-fhs}/bin/zeditor";
            };
          };

        flake = {
          # Function to override package versions
          # Usage example:
          #   zed-editor-flake.lib.overrideVersion {
          #     inherit pkgs;
          #     package = "zed-editor";
          #     version = "0.200.0";
          #     hash = "sha256-...";
          #     cargoHash = "sha256-...";
          #   }
          lib.overrideVersion =
            {
              pkgs,
              package,
              version,
              hash,
              cargoHash ? null,
              assets ? null,
            }:
            let
              packagePath =
                if package == "zed-editor" then
                  ./packages/zed-editor
                else if package == "zed-editor-preview" then
                  ./packages/zed-editor-preview
                else if package == "zed-editor-bin" then
                  ./packages/zed-editor-bin
                else if package == "zed-editor-preview-bin" then
                  ./packages/zed-editor-preview-bin
                else
                  throw "Unknown package: ${package}. Must be one of: zed-editor, zed-editor-preview, zed-editor-bin, zed-editor-preview-bin";

              isSourceBuild = package == "zed-editor" || package == "zed-editor-preview";
              isBinBuild = package == "zed-editor-bin" || package == "zed-editor-preview-bin";

              base = pkgs.callPackage packagePath { };
            in
            if isSourceBuild then
              base.overrideAttrs (old: {
                inherit version;
                src = pkgs.fetchFromGitHub {
                  owner = "zed-industries";
                  repo = "zed";
                  tag = "v${version}";
                  inherit hash;
                };
                inherit cargoHash;
              })
            else if isBinBuild then
              if assets == null then
                throw "For binary packages, you must provide 'assets' with URLs and hashes for at least one platform"
              else
                base.overrideAttrs (old: {
                  inherit version;
                  src =
                    let
                      system = pkgs.stdenv.hostPlatform.system;
                      info =
                        if pkgs.lib.hasAttr system assets then
                          assets.${system}
                        else
                          throw "No asset defined for system ${system}. Available systems: ${pkgs.lib.concatStringsSep ", " (pkgs.lib.attrNames assets)}";
                    in
                    pkgs.fetchurl {
                      url = info.url;
                      sha256 = info.sha256;
                    };
                })
            else
              throw "Unknown package type";
        };
      }
    );
}
