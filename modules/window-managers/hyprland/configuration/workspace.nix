{ config, pkgs, lib, ... }:
let
  cfg = config.modules.window-managers.hyprland;
in 
  lib.mkIf cfg.enable {
  wayland.windowManager.hyprland.settings = {

    workspace = [
      "s[false], gapsin:30, gapsout:15 15 15 15"
    ];
  };
}
