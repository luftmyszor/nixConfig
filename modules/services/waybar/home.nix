{ config, pkgs, lib, ... }:

let
  cfg = config.modules.services.waybar;

  # The moved CSS is layout-only (no palette colors) – still managed by Nix.
  waybarMovedCss = pkgs.writeTextFile {
    name = "movedWaybarStyle.css";
    text = ''

      @keyframes drop {
        from { margin-top: 0; }
	to { margin-top: 450; }
      }
    
      .module { 
	margin-top: 450px;
        animation: 10ms linear drop;	
      }


    '';};

  # normal-style.css is generated at runtime by `palette-switch` so that
  # colors can be updated without a Nix rebuild.  dropWaybar.sh still
  # toggles style.css between normal-style.css and moved-style.css.
  dropWaybarScript = pkgs.writeShellApplication {
  name = "dropWaybar.sh";
  text = ''
    #!/usr/bin/env bash
    waybar_css_dir="$HOME/.config/waybar"
    bar_normal="$waybar_css_dir/normal-style.css"
    bar_moved="$waybar_css_dir/moved-style.css"
    active_link="$waybar_css_dir/style.css"

    # toggle
    if [ "$(readlink "$active_link")" = "$bar_normal" ]; then
      ln -sf "$bar_moved" "$active_link"
    else
      ln -sf "$bar_normal" "$active_link"
    fi

    # reload waybar
    pkill -SIGUSR2 waybar

  '';};
in lib.mkIf cfg.enable {

  # normal-style.css is NOT managed by Nix – it is written at runtime by
  # `palette-switch`, which reads the active palette JSON and generates the
  # full CSS with the correct colours.  The activation script in the
  # palette-switcher module ensures the file exists after a fresh build.
  home.file.".config/waybar/moved-style.css".source = waybarMovedCss;
  home.file.".config/waybar/dropWaybar.sh".source = dropWaybarScript;
    
  # Add home specific packages
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "bottom";
      position = "top";
      exclusive = true;
      passtrough = true;    
      gtk-layer-shell = true;
      height = 0;
      modules-left = [
        "custom/spacer"
        "clock"
	"custom/divider"
	"custom/down"
      ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [
        "tray"
        "network"
        "custom/divider"
        "battery"
	"custom/spacer"
      ];
      "hyprland/window" = { format = "{}"; };
      "wlr/workspaces" = {
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        all-outputs = true;
        on-click = "activate";
      };
      battery = { format = "󰁹 {}%"; };
      tray = {
        icon-size = 13;
        tooltip = false;
        spacing = 10;
      };
      network = {
        format = "󰖩 {essid}";
        format-disconnected = "󰖪 disconnected";
      };
      clock = {
        format = " {:%I:%M %p   %m/%d} ";
        tooltip-format = ''
          <big>{:%Y %B}</big>
          <tt><small>{calendar}</small></tt>'';
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        tooltip = false;
        format-muted = " Muted";
        on-click = "pamixer -t";
        on-scroll-up = "pamixer -i 5";
        on-scroll-down = "pamixer -d 5";
        scroll-step = 5;
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
      };
      "pulseaudio#microphone" = {
        format = "{format_source}";
        tooltip = false;
        format-source = " {volume}%";
        format-source-muted = " Muted";
        on-click = "pamixer --default-source -t";
        on-scroll-up = "pamixer --default-source -i 5";
        on-scroll-down = "pamixer --default-source -d 5";
        scroll-step = 5;
      };
      "custom/divider" = {
        format = " | ";
        interval = "once";
        tooltip = false;
      };
      "custom/spacer" = {
        format = "";
        interval = "once";
        tooltip = false;
      };

      "custom/down" = {
      	format = "[down]";
	interval = "once";
	tooltip = false;
      };
      
    }];
  };
}
