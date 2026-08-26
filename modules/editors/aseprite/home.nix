{
  config,
  lib,
  pkgs,
  ...
}:

let
  # 1. Lospec Palette Importer by JRiggles
  lospecImporter = pkgs.fetchFromGitHub {
    owner = "JRiggles";
    repo = "Lospec-Palette-Importer";
    rev = "v1.6.0";
    hash = "sha256-wd7Xc49C4Az2U847PJ7FFPfx36qQJaM70cuzLWtjH0Y=";
  };

  # 2. Texture Map Generator by LiTianchu (Alternative to the itch.io Normal Toolkit)
  textureMapGen = pkgs.fetchFromGitHub {
    owner = "LiTianchu";
    repo = "aseprite-texture-map-generator";
    rev = "main";
    hash = "sha256-7S1xtV3q2r60eDI+kLj8uAW95CKj3sWB2bQElRTOYgE=";
  };

  # 3. Isometric Box Generator by darkwark
  isoBox = pkgs.fetchFromGitHub {
    owner = "darkwark";
    repo = "isobox-for-aseprite";
    rev = "master";
    hash = "sha256-mCezhx6VgMk52qJ5/DHI091ncyaKDz7wHIGkvZiZGhg";
  };

  # # 4. Community Scripts Collection (Contains Autotile & various shading scripts)
  communityScripts = pkgs.fetchFromGitHub {
    owner = "projectitis";
    repo = "aseprite-community-script-collection";
    rev = "master";
    hash = "sha256-Y9SvL2gHBQTFkiTY2E7cQ8ZU6o7yibkZ+WUugL+XtKM=";
  };
in
{
  config = lib.mkIf config.modules.editors.aseprite.enable {

    home.packages = with pkgs; [
      aseprite
    ];

    home.file = {
      # Extensions (Requires a package.json in the folder)
      ".config/aseprite/extensions/lospec".source = lospecImporter;
      ".config/aseprite/extensions/texture-map-gen".source = textureMapGen;

      # Scripts (Standalone Lua files accessed via File -> Scripts)
      ".config/aseprite/scripts/isobox".source = isoBox;
      ".config/aseprite/scripts/community".source = communityScripts;
    };

  };
}
