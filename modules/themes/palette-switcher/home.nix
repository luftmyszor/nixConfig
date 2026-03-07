{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.themes.palette-switcher;

  # Extension path used by both the shell renderer and vscode/home.nix.
  # Keep in sync with modules/editors/vscode/home.nix → paletteExtVersion.
  paletteExtVersion = "0.0.1";
  paletteThemeFile = ".vscode/extensions/palette-theme-${paletteExtVersion}/themes/palette-dark.json";

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

            # ── Module renderers ─────────────────────────────────────────────────

            render_ghostty() {
              load_palette
              local out="$HOME/.config/ghostty/colors.conf"
              mkdir -p "$(dirname "$out")"
              cat > "$out" <<GHOSTTY_EOF
      # Generated by palette-switch – do not edit by hand
      palette = 0=$black
      palette = 1=$danger
      palette = 2=$success
      palette = 3=$warning
      palette = 4=$primary
      palette = 5=$secondary
      palette = 6=$info
      palette = 7=$light
      palette = 8=$muted
      palette = 9=$danger
      palette = 10=$success
      palette = 11=$warning
      palette = 12=$primary
      palette = 13=$secondary
      palette = 14=$info
      palette = 15=$white
      background = $programBg
      foreground = $fg
      cursor-color = $accent
      cursor-text = $fg
      selection-background = $muted
      selection-foreground = $fg
      GHOSTTY_EOF
              log "Rendered Ghostty colors → $out"
            }

            render_waybar() {
              load_palette
              local css_dir="$HOME/.config/waybar"
              mkdir -p "$css_dir"
              cat > "$css_dir/normal-style.css" <<CSS_EOF
      /* Generated by palette-switch – do not edit by hand */

      window#waybar {
        background-color: $bg;
        color: $fg;
        border: 5px solid $primary;
        border-top: hidden;
        border-radius: 0px 0px 30px 30px;
      }

      box {
        transition: 1s;
        margin-top: 0px;
      }

      label.module {
        margin: 10px 10px;
        transition: 1s;
      }

      #custom-spacer {
        padding: 0px 30px;
      }

      @keyframes drop {
        from { margin-top: 0; }
        to   { margin-top: 300px; }
      }

      .module {
        margin-top: 0px;
        animation: 0.05s linear drop;
        background-color: $secondary;
      }
      CSS_EOF
              log "Rendered Waybar CSS → $css_dir/normal-style.css"

              # Ensure style.css points somewhere sensible
              local style="$css_dir/style.css"
              local moved="$css_dir/moved-style.css"
              if [[ -L "$style" && "$(readlink "$style")" == *"moved-style.css"* && -e "$moved" ]]; then
                : # keep pointing at moved-style.css
              else
                ln -sf "$css_dir/normal-style.css" "$style"
              fi
            }

            render_hyprland() {
              load_palette
              local out="$HOME/.config/hypr/palette-colors.conf"
              mkdir -p "$(dirname "$out")"
              # Strip leading '#' for Hyprland's rgb() format
              local bg_hex fg_hex primary_hex secondary_hex tertiary_hex muted_hex danger_hex
              bg_hex=$(echo "$bg" | tr -d '#')
              fg_hex=$(echo "$fg" | tr -d '#')
              primary_hex=$(echo "$primary" | tr -d '#')
              secondary_hex=$(echo "$secondary" | tr -d '#')
              tertiary_hex=$(echo "$tertiary" | tr -d '#')
              muted_hex=$(echo "$muted" | tr -d '#')
              danger_hex=$(echo "$danger" | tr -d '#')
              cat > "$out" <<HYPR_EOF
      # Generated by palette-switch – do not edit by hand
      \$paletteBg        = rgb($bg_hex)
      \$paletteFg        = rgb($fg_hex)
      \$palettePrimary   = rgb($primary_hex)
      \$paletteSecondary = rgb($secondary_hex)
      \$paletteTertiary  = rgb($tertiary_hex)
      \$paletteMuted     = rgb($muted_hex)
      \$paletteDanger    = rgb($danger_hex)
      HYPR_EOF
              log "Rendered Hyprland palette → $out"
            }

            render_neovim() {
              load_palette
              local out="$HOME/.config/nvim/lua/palette-colors.lua"
              mkdir -p "$(dirname "$out")"
              cat > "$out" <<LUA_EOF
      -- Generated by palette-switch – do not edit by hand
      -- Add  require('palette-colors').apply()  to your init.lua to use these colors
      local M = {}

      M.colors = {
        bg           = "$bg",
        programBg    = "$programBg",
        fg           = "$fg",
        primary      = "$primary",
        secondary    = "$secondary",
        tertiary     = "$tertiary",
        accent       = "$accent",
        danger       = "$danger",
        warning      = "$warning",
        success      = "$success",
        info         = "$info",
        black        = "$black",
        dark         = "$dark",
        muted        = "$muted",
        light        = "$light",
        white        = "$white",
      }

      function M.apply()
        local c = M.colors
        vim.api.nvim_set_hl(0, "Normal",      { fg = c.fg,      bg = c.bg })
        vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.fg,      bg = c.programBg })
        vim.api.nvim_set_hl(0, "Comment",     { fg = c.muted,   italic = true })
        vim.api.nvim_set_hl(0, "Keyword",     { fg = c.primary, bold   = true })
        vim.api.nvim_set_hl(0, "Function",    { fg = c.secondary })
        vim.api.nvim_set_hl(0, "String",      { fg = c.success })
        vim.api.nvim_set_hl(0, "Number",      { fg = c.warning })
        vim.api.nvim_set_hl(0, "Error",       { fg = c.danger,  bold   = true })
        vim.api.nvim_set_hl(0, "StatusLine",  { fg = c.fg,      bg = c.dark })
        vim.api.nvim_set_hl(0, "LineNr",      { fg = c.muted })
        vim.api.nvim_set_hl(0, "CursorLine",  { bg = c.dark })
        vim.api.nvim_set_hl(0, "Visual",      { bg = c.muted })
        vim.api.nvim_set_hl(0, "Pmenu",       { fg = c.fg,      bg = c.programBg })
        vim.api.nvim_set_hl(0, "PmenuSel",    { fg = c.bg,      bg = c.primary })
      end

      return M
      LUA_EOF
              log "Rendered Neovim palette → $out"
            }

            render_wofi() {
              load_palette
              local css_dir="$HOME/.config/wofi"
              mkdir -p "$css_dir"
              cat > "$css_dir/style.css" <<CSS_EOF
      /* Generated by palette-switch – do not edit by hand */

      @keyframes pri-sec-gradient-bg {
        0% {
          background-color: $primary;
        }
        50% {
          background-color: $secondary;
        }
        100% {
          background-color: $primary;
        }
      }

      window {
        background-color: $programBg;
        color: $fg;
        border: 3px solid $primary;
        border-radius: 12px;
        padding: 10px;
      }

      #input {
        background-color: $programBg;
        color: $fg;
        border: 3px solid $primary;
        border-radius: 8px;
        padding: 6px;
      }

      #entry:selected {
        color: $programBg;
        animation: 6s infinite linear pri-sec-gradient-bg;
        transition: background-color 0.5s ease;
      }

      #entry {
        padding: 4px 6px;
        background-color: transparent;
      }
      CSS_EOF
              log "Rendered Wofi CSS → $css_dir/style.css"
            }

            render_vscode() {
              load_palette
              # Write to a standalone VSCode color-theme file so that
              # settings.json (managed declaratively by home-manager) is never
              # touched.  The extension manifest is laid down by home-manager;
              # only the theme colors file is generated here.
              local theme_file="$HOME/${paletteThemeFile}"
              mkdir -p "$(dirname "$theme_file")"

              local tmp
              tmp=$(mktemp)
              jq -n \
                --arg bg        "$bg"        \
                --arg programBg "$programBg" \
                --arg fg        "$fg"        \
                --arg primary   "$primary"   \
                --arg secondary "$secondary" \
                --arg tertiary  "$tertiary"  \
                --arg accent    "$accent"    \
                --arg danger    "$danger"    \
                --arg warning   "$warning"   \
                --arg success   "$success"   \
                --arg info      "$info"      \
                --arg dark      "$dark"      \
                --arg muted     "$muted"     \
                --arg white     "$white"     \
                '{
                  "$schema": "vscode://schemas/color-theme",
                  "name": "Palette Dark",
                  "type": "dark",
                  "colors": {
                    "editor.background":                 $bg,
                    "editor.foreground":                 $fg,
                    "editor.lineHighlightBackground":    $dark,
                    "editor.selectionBackground":        $muted,
                    "editorCursor.foreground":           $accent,
                    "editorLineNumber.foreground":       $muted,
                    "editorLineNumber.activeForeground": $fg,
                    "editorIndentGuide.background1":     $muted,
                    "editorGroupHeader.tabsBackground":  $programBg,
                    "tab.activeBackground":              $dark,
                    "tab.inactiveBackground":            $programBg,
                    "tab.activeForeground":              $fg,
                    "tab.inactiveForeground":            $muted,
                    "activityBar.background":            $programBg,
                    "activityBar.foreground":            $fg,
                    "activityBar.activeBorder":          $primary,
                    "sideBar.background":                $programBg,
                    "sideBar.foreground":                $fg,
                    "sideBarTitle.foreground":           $primary,
                    "statusBar.background":              $dark,
                    "statusBar.foreground":              $fg,
                    "statusBar.noFolderBackground":      $dark,
                    "titleBar.activeBackground":         $programBg,
                    "titleBar.activeForeground":         $fg,
                    "titleBar.inactiveBackground":       $programBg,
                    "panel.background":                  $programBg,
                    "panelTitle.activeForeground":       $primary,
                    "terminal.background":               $bg,
                    "terminal.foreground":               $fg,
                    "terminal.ansiBlack":                $dark,
                    "terminal.ansiRed":                  $danger,
                    "terminal.ansiGreen":                $success,
                    "terminal.ansiYellow":               $warning,
                    "terminal.ansiBlue":                 $primary,
                    "terminal.ansiMagenta":              $secondary,
                    "terminal.ansiCyan":                 $info,
                    "terminal.ansiWhite":                $white,
                    "focusBorder":                       $primary,
                    "selection.background":              $muted,
                    "input.background":                  $programBg,
                    "input.foreground":                  $fg,
                    "input.border":                      $muted,
                    "inputOption.activeBorder":          $primary,
                    "list.activeSelectionBackground":    $dark,
                    "list.activeSelectionForeground":    $fg,
                    "list.hoverBackground":              $dark,
                    "scrollbarSlider.background":        $muted,
                    "scrollbarSlider.hoverBackground":   $primary,
                    "button.background":                 $primary,
                    "button.foreground":                 $bg,
                    "badge.background":                  $primary,
                    "badge.foreground":                  $bg,
                    "progressBar.background":            $primary
                  },
                  "tokenColors": [
                    {
                      "name": "Comment",
                      "scope": ["comment", "punctuation.definition.comment"],
                      "settings": { "foreground": $muted, "fontStyle": "italic" }
                    },
                    {
                      "name": "Keyword",
                      "scope": ["keyword", "storage.type", "storage.modifier"],
                      "settings": { "foreground": $primary, "fontStyle": "bold" }
                    },
                    {
                      "name": "Function",
                      "scope": ["entity.name.function", "support.function"],
                      "settings": { "foreground": $secondary }
                    },
                    {
                      "name": "String",
                      "scope": ["string", "string.quoted"],
                      "settings": { "foreground": $success }
                    },
                    {
                      "name": "Number",
                      "scope": ["constant.numeric"],
                      "settings": { "foreground": $warning }
                    },
                    {
                      "name": "Type",
                      "scope": ["entity.name.type", "support.type"],
                      "settings": { "foreground": $tertiary }
                    },
                    {
                      "name": "Variable",
                      "scope": ["variable", "variable.other"],
                      "settings": { "foreground": $fg }
                    }
                  ]
                }' > "$tmp"
              mv "$tmp" "$theme_file"
              log "Rendered VSCode color theme → $theme_file"
            }

            render_wallpaper() {
              local source_file="$HOME/.config/palettes/wallpaper-source.png"
              local out="$HOME/.local/share/wallpaper.png"
              if [[ ! -f "$source_file" ]]; then
                log "No wallpaper source at $source_file – skipping"
                log "(place a PNG there to enable palette-coloured wallpapers)"
                return 0
              fi
              if palette-wallpaper "$source_file" "$out"; then
                log "Rendered wallpaper → $out"
              else
                log_err "palette-wallpaper failed – check that $source_file is a valid PNG"
                return 1
              fi
            }

            # ── Reload hooks ─────────────────────────────────────────────────────

            reload_waybar() {
              if pgrep -x waybar > /dev/null 2>&1; then
                if pkill -SIGUSR2 waybar; then
                  log "Reloaded Waybar"
                else
                  log_err "Failed to signal Waybar"
                fi
              else
                log "Waybar not running – skipping reload"
              fi
            }

            reload_hyprland() {
              if command -v hyprctl > /dev/null 2>&1; then
                if hyprctl version > /dev/null 2>&1; then
                  if hyprctl reload; then
                    log "Reloaded Hyprland"
                  else
                    log_err "Failed to reload Hyprland"
                  fi
                else
                  log "Hyprland not running – skipping reload"
                fi
              else
                log "hyprctl not found – skipping Hyprland reload"
              fi
            }

            reload_neovim() {
              local reloaded=0
              for sock in /tmp/nvim*.sock /run/user/"$(id -u)"/nvim*.sock; do
                [[ -S "$sock" ]] || continue
                if nvim --server "$sock" \
                     --remote-send ':lua pcall(function() require("palette-colors").apply() end)<CR>'; then
                  reloaded=$((reloaded + 1))
                else
                  log_err "Failed to signal Neovim socket: $sock"
                fi
              done
              if [[ $reloaded -gt 0 ]]; then
                log "Signaled $reloaded Neovim instance(s)"
              else
                log "No running Neovim instances found"
              fi
            }

            reload_ghostty() {
              if pgrep ghostty > /dev/null 2>&1; then
                if pkill -SIGUSR2 ghostty; then
                  log "Reloaded Ghostty"
                else
                  log_err "Failed to signal Ghostty"
                fi
              else
                log "Ghostty not running – skipping reload"
              fi
            }

            reload_wallpaper() {
              local out="$HOME/.local/share/wallpaper.png"
              [[ -f "$out" ]] || return 0
              if command -v swww > /dev/null 2>&1; then
                if swww query > /dev/null 2>&1; then
                  if swww img "$out"; then
                    log "Set wallpaper via swww"
                  else
                    log_err "Failed to set wallpaper via swww"
                  fi
                else
                  log "swww not running – skipping wallpaper apply"
                fi
              else
                log "swww not found – skipping wallpaper apply"
              fi
            }

            reload_vscode() {
              log "VSCode has no live-reload signal – open VSCode and run 'Developer: Reload Window' to apply the new theme"
            }

            # ── Apply all modules ─────────────────────────────────────────────────

            apply_all() {
              local palette_name
              palette_name=$(jq -r '.name // "unknown"' "$ACTIVE_LINK")
              log "Applying palette: $palette_name"

              render_ghostty   || log_err "Ghostty render failed"
              render_waybar    || log_err "Waybar render failed"
              render_hyprland  || log_err "Hyprland render failed"
              render_neovim    || log_err "Neovim render failed"
              render_wofi      || log_err "Wofi render failed"
              render_vscode    || log_err "VSCode render failed"
              render_wallpaper || true

              reload_ghostty   || true
              reload_waybar    || true
              reload_hyprland  || true
              reload_neovim    || true
              reload_vscode    || true
              reload_wallpaper || true
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
