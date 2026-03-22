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

  # ── Sub-scripts directory (relative to $HOME) ────────────────────────────
  subScriptsDir = ".local/share/palette-switch/modules";

  # ── palette-wallpaper script ──────────────────────────────────────────────
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

  # ── palette-switch master script ──────────────────────────────────────────
  # Module sub-scripts are deployed to ~/.local/share/palette-switch/modules/
  # by home.file (conditionally per-module) and sourced automatically here.
  paletteSwitchScript = pkgs.writeShellApplication {
    name = "palette-switch";
    runtimeInputs = [
      pkgs.jq
      paletteWallpaperScript
    ];
    text = ''
      PALETTES_DIR="$HOME/.config/palettes"
      ACTIVE_LINK="$PALETTES_DIR/active.json"
      MODULES_DIR="$HOME/.local/share/palette-switch/modules"

      log()     { echo "[palette-switch] $*"; }
      log_err() { echo "[palette-switch] ERROR: $*" >&2; }

      # ── Helpers ──────────────────────────────────────────────────────────
      # shellcheck disable=SC2034
      # Variables set here are consumed by dynamically-sourced sub-scripts;
      # shellcheck cannot see those usages so we suppress the false positives.
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

      # ── Load module sub-scripts ───────────────────────────────────────────
      # Each sub-script appends its name to PALETTE_SWITCH_RENDERERS and
      # defines render_<name>() / reload_<name>() functions.
      PALETTE_SWITCH_RENDERERS=()
      if [[ -d "$MODULES_DIR" ]]; then
        for _ps_script in "$MODULES_DIR"/*.sh; do
          # shellcheck disable=SC1090
          [[ -f "$_ps_script" ]] && source "$_ps_script"
        done
      fi
      unset _ps_script

      # ── Apply all enabled modules ─────────────────────────────────────────
      apply_all() {
        local palette_name _module
        palette_name=$(jq -r '.name // "unknown"' "$ACTIVE_LINK")
        log "Applying palette: $palette_name"

        for _module in "''${PALETTE_SWITCH_RENDERERS[@]}"; do
          "render_''${_module}" || log_err "''${_module} render failed"
        done

        for _module in "''${PALETTE_SWITCH_RENDERERS[@]}"; do
          if declare -f "reload_''${_module}" > /dev/null 2>&1; then
            "reload_''${_module}" || true
          fi
        done
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
          if declare -f render_wallpaper > /dev/null 2>&1; then
            render_wallpaper
          fi
          if declare -f reload_wallpaper > /dev/null 2>&1; then
            reload_wallpaper
          fi
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
  home.file =
    lib.mapAttrs' (
      name: data: lib.nameValuePair ".config/palettes/${name}.json" { text = builtins.toJSON data; }
    ) palettes

    # ── Deploy module sub-scripts conditionally ───────────────────────────
    // lib.optionalAttrs config.modules.terminals.ghostty.enable {
      "${subScriptsDir}/ghostty.sh".text = builtins.readFile ./modules/ghostty.sh;
    }
    // lib.optionalAttrs config.modules.services.waybar.enable {
      "${subScriptsDir}/waybar.sh".text = builtins.readFile ./modules/waybar.sh;
    }
    // lib.optionalAttrs config.modules.window-managers.hyprland.enable {
      "${subScriptsDir}/hyprland.sh".text = builtins.readFile ./modules/hyprland.sh;
    }
    // {
      # neovim has no NixOS module option in this config; always deploy
      "${subScriptsDir}/neovim.sh".text = builtins.readFile ./modules/neovim.sh;
    }
    // lib.optionalAttrs config.modules.services.wofi.enable {
      "${subScriptsDir}/wofi.sh".text = builtins.readFile ./modules/wofi.sh;
    }
    // lib.optionalAttrs config.modules.editors.vscode.enable {
      "${subScriptsDir}/vscode.sh".text = builtins.readFile ./modules/vscode.sh;
    }
    // {
      # wallpaper sub-script is always deployed; reload gracefully skips if
      # swww is absent
      "${subScriptsDir}/wallpaper.sh".text = builtins.readFile ./modules/wallpaper.sh;
    };

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
