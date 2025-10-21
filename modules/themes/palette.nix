# modules/theme/palette.nix

{
  # Base background/foreground
  bg       = "#1e1e2e";
  programBg= "#12121c";
  fg       = "#cdd6f4";

  # Accent colors
  primary  = "#89b4fa"; # blue
  secondary = "#f38ba8"; # pink/red
  tertiary = "#a6e3a1"; # green

  # Semantic intent (for clarity in use)
  accent   = "#89b4fa"; # same as primary
  danger   = "#f38ba8";
  warning  = "#f9e2af";
  success  = "#a6e3a1";
  info     = "#94e2d5";

  # Greyscale shades
  black    = "#11111b";
  dark     = "#181825";
  muted    = "#313244";
  light    = "#bac2de";
  white    = "#ffffff";

  # Transparent versions
  bgTransparent = "rgba(30, 30, 46, 0.8)";
  darkTransparent = "rgba(24, 24, 37, 0.6)";
}

