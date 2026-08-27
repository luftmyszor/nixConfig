{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Extensions
  lospecImporter = pkgs.stdenv.mkDerivation {
    name = "lospec-palette-importer";
    src = pkgs.fetchFromGitHub {
      owner = "JRiggles";
      repo = "Lospec-Palette-Importer";
      rev = "v1.6.0";
      hash = "sha256-wd7Xc49C4Az2U847PJ7FFPfx36qQJaM70cuzLWtjH0Y=";
    };
    patchPhase = ''
      # Find the line containing /usr/bin/env, completely wipe it out, and replace it with absolute Nix paths
      sed -i "s|.*/usr/bin/env.*|command = 'env SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${pkgs.curl}/bin/curl -Ls \"' .. url .. '\"'|g" extension/lospec-palette-importer.lua
    '';
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  # EaseSprite by JRiggles
  easeSprite = pkgs.stdenv.mkDerivation {
    name = "easesprite";
    src = pkgs.fetchFromGitHub {
      owner = "JRiggles";
      repo = "EaseSprite";
      rev = "main";
      hash = "sha256-jr/vccBqxW9HYtK6LzaNAyQYwS+KCbIs/DW4HDHHAbg=";
    };
    installPhase = ''
      mkdir -p ${builtins.placeholder "out"}

      # Extract the package.json to the root, no matter the repo structure
      if [ -d "extension" ]; then
        cp -r extension/* ${builtins.placeholder "out"}/
      else
        cp -r * ${builtins.placeholder "out"}/
      fi
    '';
  };

  # Scripts
  isoBox = pkgs.fetchFromGitHub {
    owner = "darkwark";
    repo = "isobox-for-aseprite";
    rev = "ddf34b1b33540922548fe1073f45e14b1e93fdb5";
    hash = "sha256-mCezhx6VgMk52qJ5/DHI091ncyaKDz7wHIGkvZiZGhg=";
  };

in
{
  config = lib.mkIf config.modules.editors.aseprite.enable {

    home.packages = with pkgs; [
      aseprite
    ];

    home.file = {
      ".config/aseprite/extensions/lospec" = {
        source = "${lospecImporter}/extension";
        recursive = true;
      };

      ".config/aseprite/extensions/easeSprite" = {
        source = easeSprite;
        recursive = true;
      };

      ".config/aseprite/scripts/isobox" = {
        source = isoBox;
        recursive = true;
      };

      # Directly link the file instead of using writeTextFile!
      ".config/aseprite/scripts/spatial_ease.lua".source = ./scripts/spatial_ease.lua;
    };

  };
}
