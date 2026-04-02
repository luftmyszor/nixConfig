{ lib, ... }:
{
  options.modules.themes.xcursor = {
    enable = lib.mkEnableOption "palette-driven XCursor theme generation";

    baseTheme = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = ''
        Name of the XCursor base theme to use.  Base themes live under
        modules/themes/xcursor/bases/<name>/ and contain SVG cursor files
        with colour placeholders (@@PRIMARY@@, @@FG@@, @@BG@@, …) that are
        substituted from the active palette when palette-switch runs.
      '';
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Cursor size in pixels (used for XCURSOR_SIZE and hyprctl setcursor).";
    };
  };
}
