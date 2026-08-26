{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Extensions
  lospecImporter = pkgs.fetchFromGitHub {
    owner = "JRiggles";
    repo = "Lospec-Palette-Importer";
    rev = "v1.6.0";
    hash = "sha256-wd7Xc49C4Az2U847PJ7FFPfx36qQJaM70cuzLWtjH0Y=";
  };

  textureMapGen = pkgs.fetchFromGitHub {
    owner = "LiTianchu";
    repo = "aseprite-texture-map-generator";
    rev = "9bd05f18022173551345af88901f880270a729a3";
    hash = "sha256-7S1xtV3q2r60eDI+kLj8uAW95CKj3sWB2bQElRTOYgE=";
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

      ".config/aseprite/extensions/texture-map-gen" = {
        source = textureMapGen;
        recursive = true;
      };

      ".config/aseprite/scripts/isobox" = {
        source = isoBox;
        recursive = true;
      };

    };

  };
}
