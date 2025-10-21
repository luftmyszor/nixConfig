{ config, kgs, lib, ... }:
let
  cfg = config.modules.window-managers.hyprland;
in
  lib.mkIf cfg.enable {
  wayland.windowManager.hyprland.settings = {
    exec = [
      "echo s"
    ];
  };
}
