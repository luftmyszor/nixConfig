{ config, pkgs, lib, palette, ... }:

let cfg = config.modules.terminals.ghostty;
in lib.mkIf cfg.enable {
  programs.ghostty = {
    enable = true;
    settings = {};  # Clear existing settings
  };

  # Manually create the Ghostty config file with proper format
  home.file.".config/ghostty/config".text = ''
    palette = 0=${palette.black}
    palette = 1=${palette.danger}
    palette = 2=${palette.success}
    palette = 3=${palette.warning}
    palette = 4=${palette.primary}
    palette = 5=${palette.secondary}
    palette = 6=${palette.info}
    palette = 7=${palette.light}
    palette = 8=${palette.muted}
    palette = 9=${palette.danger}
    palette = 10=${palette.success}
    palette = 11=${palette.warning}
    palette = 12=${palette.primary}
    palette = 13=${palette.secondary}
    palette = 14=${palette.info}
    palette = 15=${palette.white}
    background = ${palette.programBg}
    foreground = ${palette.fg}
    cursor-color = ${palette.accent}
    cursor-text = ${palette.fg}
    selection-background = ${palette.muted}
    selection-foreground = ${palette.fg}
  '';
}
