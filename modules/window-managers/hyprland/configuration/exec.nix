{ config, lib, ... }:
let
  cfg = config.modules.window-managers.hyprland;
in
  lib.mkIf cfg.enable {
  wayland.windowManager.hyprland.settings = {
    exec = [
      "echo s"
    ];

    # Run once at compositor startup to apply the full palette: renders
    # colours for Waybar/Wofi/Ghostty/etc. and calls hyprctl setcursor so
    # the cursor theme is live immediately.  home-manager activation already
    # generates the cursor files, but hyprctl must be called while Hyprland
    # is running, hence the exec-once here.
    exec-once = lib.optionals config.modules.themes.palette-switcher.enable [
      "palette-switch apply"
    ];
  };
}
