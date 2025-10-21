{ config, pkgs, lib, palette, ... }:

let
  enabled = config.modules.services.wofi.enable;

  colors = palette;

  wofiConfig = ''
    [wofi]
    allow_markup = true
    show_icons = true
    prompt = Search...
    width = 600
    location = center
    lines = 15
    hide_scroll = true
    insensitive = true'';

    # --- style.css using palette ---
    wofiStyle = ''

    @keyframes pri-sec-gradient-bg {
      0% {
        background-color: ${palette.primary};
      }
      50% {
        background-color: ${palette.secondary};
      }
      100% { 
        background-color: ${palette.primary};
      }
    }


    window {
      background-color: ${palette.programBg};
      color: ${palette.fg};
      border: 3px solid ${palette.primary};
      border-radius: 12px;
      padding: 10px;
    }

    #input {
      background-color: ${palette.programBg};
      color: ${palette.fg};
      border: 3px solid ${palette.primary};
      border-radius: 8px;
      padding: 6px;
    }


    #entry:selected { 
      color: ${palette.programBg};
      animation: 6s infinite linear pri-sec-gradient-bg;
      transition: background-color 0.5s ease;
    }

    #entry {
      padding: 4px 6px;
      background-color: transparent;
    }  '';
in

{
  home.file.".config/wofi/config".text = lib.mkIf enabled wofiConfig;
  home.file.".config/wofi/style.css".text = lib.mkIf enabled wofiStyle;
}

