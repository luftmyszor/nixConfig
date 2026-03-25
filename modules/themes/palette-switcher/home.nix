{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.themes.palette-switcher;

  # ── Automatically discover all palette .nix files in the catalogue ────────
  catalogueDir = ../palleteCatalogue;

  # Build a map of palette-name → palette-data by reading every .nix file in
  # the catalogue directory.  The palette name is taken from the file's own
  # `name` attribute when present; otherwise it falls back to the filename
  # (without the .nix extension).
  allCatalogueEntries = builtins.readDir catalogueDir;
  nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames allCatalogueEntries);

  palettes =
    builtins.listToAttrs (
      builtins.map (
        filename:
        let
          data = import (catalogueDir + "/${filename}");
          paletteName = data.name or (lib.removeSuffix ".nix" filename);
        in
        {
          name = paletteName;
          value = data // { name = paletteName; };
        }
      ) nixFiles
    );

  # ── Auto-load scripts from scripts/ ──────────────────────────────────────
  # Every .nix file in the scripts/ subdirectory must return an attrset with:
  #   priority  (int)    – lower numbers run first; render=1, reload=2
  #   functions (string) – bash function definitions to include in the script
  #   apply     (string) – bash statements to run inside apply_all()
  # Files are sorted by priority before concatenation so that renders always
  # precede reloads regardless of the alphabetical order of the filenames.
  scriptsDir = ./scripts;
  scriptFiles = builtins.filter (n: lib.hasSuffix ".nix" n)
                  (builtins.attrNames (builtins.readDir scriptsDir));
  loadedScripts = lib.sort (a: b: a.priority < b.priority)
                    (map (n: import (scriptsDir + "/${n}")) scriptFiles);
  allFunctions = lib.concatMapStrings (s: s.functions) loadedScripts;
  allApply     = lib.concatMapStrings (s: s.apply)     loadedScripts;

  # ── palette-wallpaper script ──────────────────────────────────────────────
  # Takes a PNG file, applies a top-to-bottom gradient (primary→secondary) to
  # all non-transparent pixels, and fills transparent pixels with the bg color.
  # Reads the active palette from ~/.config/palettes/active.json.
  paletteWallpaperScript = pkgs.writeShellApplication {
    name = "palette-wallpaper";
    runtimeInputs = [ (pkgs.python3.withPackages (ps: [ ps.pillow ])) ];
    text = ''
            if [[ $# -lt 1 ]]; then
              echo "Usage: palette-wallpaper <input.png> [output.png]" >&2
              exit 1
            fi
            python3 - "$@" <<'PYEOF'
      import sys, os, json
      from PIL import Image

      def hex_to_rgb(h):
          h = h.lstrip('#')
          return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

      input_path  = sys.argv[1]
      output_path = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.local/share/wallpaper.png")

      palette_path = os.environ.get("PALETTE_FILE",
                     os.path.expanduser("~/.config/palettes/active.json"))
      if not os.path.isfile(palette_path):
          print(f"[palette-wallpaper] ERROR: palette file not found: {palette_path}", file=sys.stderr)
          sys.exit(1)

      with open(palette_path) as f:
          palette = json.load(f)

      primary   = hex_to_rgb(palette["primary"])
      secondary = hex_to_rgb(palette["secondary"])
      bg        = hex_to_rgb(palette["bg"])

      img = Image.open(input_path).convert("RGBA")
      w, h = img.size

      # Build a 1-pixel-wide vertical gradient strip, then tile to full width.
      gradient = Image.new("RGB", (1, h))
      for y in range(h):
          t = y / max(h - 1, 1)
          r = round(primary[0] + (secondary[0] - primary[0]) * t)
          g = round(primary[1] + (secondary[1] - primary[1]) * t)
          b = round(primary[2] + (secondary[2] - primary[2]) * t)
          gradient.putpixel((0, y), (r, g, b))
      gradient = gradient.resize((w, h), Image.NEAREST)

      # Solid background layer.
      background = Image.new("RGB", (w, h), bg)

      # Composite: alpha=255 (non-empty pixel) → gradient colour
      #            alpha=0   (empty pixel)     → bg colour
      _, _, _, alpha = img.split()
      out = Image.composite(gradient, background, alpha)

      os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
      out.save(output_path)
      print(f"[palette-wallpaper] Saved → {output_path}")
      PYEOF
    '';
  };

  # ── palette-switch script ─────────────────────────────────────────────────
  paletteSwitchScript = pkgs.writeShellApplication {
    name = "palette-switch";
    runtimeInputs = [
      pkgs.jq
      paletteWallpaperScript
    ];
    text = ''
            PALETTES_DIR="$HOME/.config/palettes"
            ACTIVE_LINK="$PALETTES_DIR/active.json"

            log()     { echo "[palette-switch] $*"; }
            log_err() { echo "[palette-switch] ERROR: $*" >&2; }

            # ── Helpers ──────────────────────────────────────────────────────────
            load_palette() {
              if [[ ! -f "$ACTIVE_LINK" ]]; then
                log_err "No active palette found at $ACTIVE_LINK"
                log_err "Run: palette-switch <name>  (e.g. palette-switch tokyo-night)"
                exit 1
              fi
              bg=$(jq -r '.bg'            "$ACTIVE_LINK")
              programBg=$(jq -r '.programBg'    "$ACTIVE_LINK")
              fg=$(jq -r '.fg'            "$ACTIVE_LINK")
              primary=$(jq -r '.primary'       "$ACTIVE_LINK")
              secondary=$(jq -r '.secondary'     "$ACTIVE_LINK")
              tertiary=$(jq -r '.tertiary'      "$ACTIVE_LINK")
              accent=$(jq -r '.accent'        "$ACTIVE_LINK")
              danger=$(jq -r '.danger'        "$ACTIVE_LINK")
              warning=$(jq -r '.warning'       "$ACTIVE_LINK")
              success=$(jq -r '.success'       "$ACTIVE_LINK")
              info=$(jq -r '.info'          "$ACTIVE_LINK")
              black=$(jq -r '.black'         "$ACTIVE_LINK")
              dark=$(jq -r '.dark'          "$ACTIVE_LINK")
              muted=$(jq -r '.muted'         "$ACTIVE_LINK")
              light=$(jq -r '.light'         "$ACTIVE_LINK")
              white=$(jq -r '.white'         "$ACTIVE_LINK")
            }

            # ── Module functions (auto-loaded from scripts/) ──────────────────────
            ${allFunctions}

            # ── Apply all modules ─────────────────────────────────────────────────

            apply_all() {
              local palette_name
              palette_name=$(jq -r '.name // "unknown"' "$ACTIVE_LINK")
              log "Applying palette: $palette_name"

              ${allApply}
            }

            # ── Usage ─────────────────────────────────────────────────────────────

            usage() {
              cat <<'USAGE_EOF'
      Usage: palette-switch <command>

      Commands:
        list       List available palettes (active one marked with *)
        apply      Re-render all module configs from the current active palette
                   and reload affected programs
        wallpaper  Re-render and apply the wallpaper only
                   (reads ~/.config/palettes/wallpaper-source.png)
        <name>     Switch to the named palette, render configs, and reload programs

      Examples:
        palette-switch list
        palette-switch tokyo-night
        palette-switch gruvbox
        palette-switch wallpaper
        palette-switch apply
      USAGE_EOF
            }

            # ── Main ──────────────────────────────────────────────────────────────

            cmd="''${1:-}"
            case "$cmd" in
              list)
                if [[ ! -d "$PALETTES_DIR" ]]; then
                  log_err "Palettes directory not found: $PALETTES_DIR"
                  exit 1
                fi
                active_name=""
                [[ -L "$ACTIVE_LINK" ]] && active_name=$(basename "$(readlink "$ACTIVE_LINK")" .json)
                for f in "$PALETTES_DIR"/*.json; do
                  [[ -f "$f" ]] || continue
                  name=$(basename "$f" .json)
                  [[ "$name" == "active" ]] && continue
                  if [[ "$name" == "$active_name" ]]; then
                    echo "* $name (active)"
                  else
                    echo "  $name"
                  fi
                done
                ;;
              apply)
                apply_all
                ;;
              wallpaper)
                render_wallpaper
                reload_wallpaper
                ;;
              "")
                usage
                ;;
              *)
                palette_file="$PALETTES_DIR/$cmd.json"
                if [[ ! -f "$palette_file" ]]; then
                  log_err "Palette '$cmd' not found in $PALETTES_DIR"
                  log_err "Use 'palette-switch list' to see available palettes"
                  exit 1
                fi
                ln -sf "$cmd.json" "$ACTIVE_LINK"
                log "Switched active palette → $cmd"
                apply_all
                ;;
            esac
    '';
  };

  # ── wofi-theme-switch script ──────────────────────────────────────────────
  # Opens a wofi dmenu showing all available palettes (active one marked with
  # "(active)").  Selecting an entry calls palette-switch to apply that theme.
  wofiThemeSwitchScript = pkgs.writeShellApplication {
    name = "wofi-theme-switch";
    runtimeInputs = [
      pkgs.wofi
      paletteSwitchScript
    ];
    text = ''
      PALETTES_DIR="$HOME/.config/palettes"
      ACTIVE_LINK="$PALETTES_DIR/active.json"

      if [[ ! -d "$PALETTES_DIR" ]]; then
        echo "[wofi-theme-switch] Palettes directory not found: $PALETTES_DIR" >&2
        exit 1
      fi

      # Determine the currently active palette name
      active_name=""
      if [[ -L "$ACTIVE_LINK" ]]; then
        active_name=$(basename "$(readlink "$ACTIVE_LINK")" .json)
      fi

      # Build the list shown in wofi
      theme_list=""
      for f in "$PALETTES_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        [[ "$name" == "active" ]] && continue
        if [[ "$name" == "$active_name" ]]; then
          theme_list+="$name (active)"$'\n'
        else
          theme_list+="$name"$'\n'
        fi
      done

      if [[ -z "$theme_list" ]]; then
        echo "[wofi-theme-switch] No palettes found in $PALETTES_DIR" >&2
        exit 1
      fi

      # Show picker and capture selection
      selected=$(printf '%s' "$theme_list" | wofi --dmenu --prompt "Switch Theme" --insensitive)

      # Nothing selected – user dismissed the picker
      [[ -z "$selected" ]] && exit 0

      # Strip the " (active)" suffix if present
      theme="''${selected% (active)}"

      palette-switch "$theme"
    '';
  };

in
lib.mkIf cfg.enable {

  # ── Deploy palette JSON files (auto-detected from palleteCatalogue) ────────
  home.file = lib.mapAttrs' (
    name: data: lib.nameValuePair ".config/palettes/${name}.json" { text = builtins.toJSON data; }
  ) palettes;

  # ── Install the palette-switch, palette-wallpaper, and wofi-theme-switch scripts ──
  home.packages = [
    paletteSwitchScript
    paletteWallpaperScript
    wofiThemeSwitchScript
  ];

  # ── Activation: set up the active symlink and generate initial configs ─────
  home.activation.palette-switcher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PALETTES_DIR="$HOME/.config/palettes"
    ACTIVE_LINK="$PALETTES_DIR/active.json"
    DEFAULT_PALETTE="${cfg.defaultPalette}"

    # Set up the active symlink if it doesn't exist yet
    if [[ ! -L "$ACTIVE_LINK" ]]; then
      $DRY_RUN_CMD ln -sf "$DEFAULT_PALETTE.json" "$ACTIVE_LINK"
    fi

    # Render all module configs from the current active palette
    $DRY_RUN_CMD ${paletteSwitchScript}/bin/palette-switch apply || true
  '';
}
