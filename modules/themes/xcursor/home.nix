{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.themes.xcursor;

  # All base-theme directories bundled alongside this module in the nix store.
  basesDir = ./bases;
  baseNames = builtins.attrNames (builtins.readDir basesDir);

  # Build home.file entries that deploy every base theme's files under
  # ~/.local/share/xcursor-bases/<name>/.  home-manager links each directory
  # entry recursively, making the SVGs (and metadata files) readable at
  # runtime by the palette-switch render_xcursor function.
  baseFileEntries = lib.listToAttrs (
    map (name: {
      name = ".local/share/xcursor-bases/${name}";
      value = {
        source = basesDir + "/${name}";
      };
    }) baseNames
  );

in
lib.mkIf cfg.enable {

  # ── Runtime tools required by the render_xcursor script ───────────────────
  # rsvg-convert converts palette-coloured SVGs to PNGs; xcursorgen assembles
  # the PNG frames into binary XCursor files.  Both must be on PATH when
  # palette-switch runs (they are added to the user's nix-profile PATH here).
  home.packages = [
    pkgs.librsvg         # provides rsvg-convert
    pkgs.xorg.xcursorgen # provides xcursorgen
    pkgs.xorg.xrdb       # provides xrdb (for XWayland cursor theme via X resources)
  ];

  # ── Deploy base theme assets and the runtime config ───────────────────────
  home.file = lib.mkMerge [
    baseFileEntries

    # Runtime config read by render_xcursor to know which base theme and
    # cursor size to use.  Changing these values requires a home-manager
    # rebuild (base theme = cursor shapes; colours are switched at runtime).
    {
      ".config/xcursor/config.json".text = builtins.toJSON {
        baseTheme = cfg.baseTheme;
        size = cfg.size;
      };

      # XWayland (and any X11/Electron app running over it) reads the cursor
      # theme from the X resource database rather than XCURSOR_THEME.  This
      # file is loaded by Hyprland's exec-once via `xrdb -merge ~/.Xresources`
      # so that apps like VSCode pick up the palette-cursor theme even when
      # they fall back to XWayland.  The stable "palette-cursor" name is used
      # so this file never needs to change across palette switches.
      ".Xresources".text = ''
        Xcursor.theme: palette-cursor
        Xcursor.size:  ${toString cfg.size}
      '';
    }
  ];

  # ── Cursor environment variables ───────────────────────────────────────────
  # XCURSOR_THEME points all XCursor-aware apps to the generated theme.
  # XCURSOR_SIZE is used by Wayland compositors and XWayland.
  home.sessionVariables = {
    XCURSOR_THEME = "palette-cursor";
    XCURSOR_SIZE = toString cfg.size;
  };

  # ── Ensure the icons directory exists for the generated theme ─────────────
  home.activation.xcursor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
  '';
}
