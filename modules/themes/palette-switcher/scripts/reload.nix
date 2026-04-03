# ── Reload functions ─────────────────────────────────────────────────────────
# Each reload_* function signals a running application to pick up the new
# configuration file written by the corresponding render_* function.
# priority = 2 ensures reloads always run after renders (see render.nix).
{
  priority = 2;

  functions = ''
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

    reload_vscode() {
      # VSCode watches settings.json via inotify and hot-reloads colour
      # customisations automatically – no signal or restart is required as
      # long as render_vscode writes the file in-place (preserving its inode).
      if pgrep -x code > /dev/null 2>&1 || pgrep -x code-fhs > /dev/null 2>&1; then
        log "VSCode is running – colours applied via settings.json file watch"
      else
        log "VSCode not running – colours will apply on next launch"
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
  '';

  apply = ''
    reload_ghostty   || true
    reload_waybar    || true
    reload_hyprland  || true
    reload_neovim    || true
    reload_vscode    || true
    reload_wallpaper || true
  '';
}
