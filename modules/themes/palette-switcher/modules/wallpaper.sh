# palette-switch module: wallpaper
# Rendered and sourced automatically by palette-switch.
# Always deployed when palette-switcher is enabled.

PALETTE_SWITCH_RENDERERS+=(wallpaper)

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
