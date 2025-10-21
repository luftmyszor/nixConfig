{ lib, ... }:
{
  options.modules.window-managers.hyprland.enable = lib.mkEnableOption "Enable hyprland tiling manager";
}
