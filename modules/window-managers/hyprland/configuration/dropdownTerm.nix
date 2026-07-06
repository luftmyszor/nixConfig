{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.window-managers.hyprland;
in
lib.mkIf cfg.enable {
  wayland.windowManager.hyprland.settings = {

    workspace = [
      "special:dropdown, on-created-empty:$terminal"
      "s[true], gapsout:0 0 750 0, gapsin:0, border:false"
    ];
    windowrulev2 = [
      "float,onworkspace: special:dropdown"
      "pin,onworkspace: special:dropdown"

    ];
    bind = [
      "$mod,grave, togglespecialworkspace, special:dropdown"
    ];
    animation = [
      "specialWorkspace, 1, 4, default, slidefadevert -50%"
    ];
  };
}
