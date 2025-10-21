{ config, lib, pkgs, ... }:

let
  cfg = config.modules.window-managers.hyprland;
in lib.mkIf cfg.enable {
  programs.hyprland.enable = true;
}
