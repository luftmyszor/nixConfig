{ lib, ... }:
{
  options.modules.themes.palette-switcher = {
    enable = lib.mkEnableOption "runtime palette switcher (no rebuild needed to switch themes)";

    defaultPalette = lib.mkOption {
      type = lib.types.str;
      default = "tokyo-night";
      description = "Name of the palette to activate on a fresh install. Must match a file in ~/.config/palettes/<name>.json.";
    };
  };
}
