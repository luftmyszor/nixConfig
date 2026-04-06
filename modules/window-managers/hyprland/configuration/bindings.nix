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
    bind = lib.concatLists [
      [
        "$mod, F, exec, firefox"
        "$mod, RETURN, exec, $terminal"
        "$mod, M, exec, hyprctl dispatch exit"
        "$mod, W, exec, hyprctl dispatch killactive"
        "$mod, Tab, cyclenext,"
        "$mod, Tab, bringactivetotop,"
        "$mod_SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
      ]
      (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "   $mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ))
      (
        if config.modules.services.wofi.enable then
          [ "$mod, R, exec, wofi --show drun -c ~/.config/wofi/config -s ~/.config/wofi/style.css" ]
        else
          [ ]
      )
    ];

    binds = {
      drag_threshold = "10";
    };
    bindm = [
      "$mod, CONTROL_L, movewindow"
      "$mod, mouse:272, movewindow"
      "$mod, ALT_L, resizeWindow"
      "$mod, mouse:273, resizeWindow"
    ];
    bindc = [
      "$mod, mouse:272, togglefloating"
    ];
    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
      ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%- "
    ];
  };
}
