{ config, lib, ... }:

let
  enabled = config.modules.services.wofi.enable;

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
in

{
  # style.css is NOT managed by Nix – it is written at runtime by
  # `palette-switch` (render_wofi) so that theme switches take effect
  # immediately without rebuilding the system.
  home.file = lib.mkIf enabled {
    ".config/wofi/config".text = wofiConfig;
  };
}
