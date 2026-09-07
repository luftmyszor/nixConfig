{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.window-managers.hyprland;
  paletteBlueprint =
    builtins.replaceStrings
      [
        "__ENABLE_WOFI__"
        "__ENABLE_PALETTE_SWITCHER__"
        "__ENABLE_XCURSOR__"
        "__XCURSOR_SIZE__"
      ]
      [
        (if config.modules.services.wofi.enable then "true" else "false")
        (if config.modules.themes.palette-switcher.enable then "true" else "false")
        (if config.modules.themes.xcursor.enable then "true" else "false")
        (toString config.modules.themes.xcursor.size)
      ]
      (builtins.readFile ./configuration/palette-blueprint.lua);
in
{
  config = lib.mkIf cfg.enable {

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      settings = { };
      extraConfig = paletteBlueprint;

    };
  };
}
