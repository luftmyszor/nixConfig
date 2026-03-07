{ config, pkgs, lib, ... }:

let cfg = config.modules.terminals.ghostty;
in lib.mkIf cfg.enable {
  # programs.ghostty manages ~/.config/ghostty/config, so we configure the
  # runtime palette include here rather than via a separate home.file (which
  # would collide with the file that programs.ghostty generates).
  programs.ghostty = {
    enable = true;
    settings = {
      # Include the runtime-generated palette file produced by `palette-switch`.
      # Run `palette-switch apply` or `palette-switch <name>` to
      # (re-)generate ~/.config/ghostty/colors.conf after switching themes.
      # Note: `theme-switch` updates ~/.cache/theme/current/ (CSS vars / JSON),
      # while `palette-switch` updates this Ghostty-specific colors.conf format.
      "config-file" = "~/.config/ghostty/colors.conf";
    };
  };
}
