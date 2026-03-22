# palette-switch module: vscode
# Rendered and sourced automatically by palette-switch.

PALETTE_SWITCH_RENDERERS+=(vscode)

render_vscode() {
  load_palette
  # Two-file approach:
  #   settings.base.json  – nix-store symlink managed by home.nix;
  #                         contains all static (non-color) settings.
  #   settings.colors.json – mutable file managed by this function;
  #                          contains only the two color blocks.
  #   settings.json        – mutable file, merged from the two above;
  #                          never owned by home-manager so there is
  #                          no checkLinkTargets conflict.
  local vscode_dir="$HOME/.config/Code/User"
  local base_file="$vscode_dir/settings.base.json"
  local colors_file="$vscode_dir/settings.colors.json"
  local settings_file="$vscode_dir/settings.json"
  mkdir -p "$vscode_dir"

  # Write the color blocks to the dedicated colors file.
  local tmp_colors
  tmp_colors=$(mktemp)
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
      "workbench.colorCustomizations": {
        "editor.background":                  $bg,
        "editor.foreground":                  $fg,
        "editor.lineHighlightBackground":     $dark,
        "editor.selectionBackground":         $muted,
        "editorCursor.foreground":            $accent,
        "editorLineNumber.foreground":        $muted,
        "editorLineNumber.activeForeground":  $fg,
        "editorIndentGuide.background1":      $muted,
        "editorGroupHeader.tabsBackground":   $programBg,
        "tab.activeBackground":               $dark,
        "tab.inactiveBackground":             $programBg,
        "tab.activeForeground":               $fg,
        "tab.inactiveForeground":             $muted,
        "activityBar.background":             $programBg,
        "activityBar.foreground":             $fg,
        "activityBar.activeBorder":           $primary,
        "sideBar.background":                 $programBg,
        "sideBar.foreground":                 $fg,
        "sideBarTitle.foreground":            $primary,
        "statusBar.background":               $dark,
        "statusBar.foreground":               $fg,
        "statusBar.noFolderBackground":       $dark,
        "titleBar.activeBackground":          $programBg,
        "titleBar.activeForeground":          $fg,
        "titleBar.inactiveBackground":        $programBg,
        "panel.background":                   $programBg,
        "panelTitle.activeForeground":        $primary,
        "terminal.background":                $bg,
        "terminal.foreground":                $fg,
        "terminal.ansiBlack":                 $dark,
        "terminal.ansiRed":                   $danger,
        "terminal.ansiGreen":                 $success,
        "terminal.ansiYellow":                $warning,
        "terminal.ansiBlue":                  $primary,
        "terminal.ansiMagenta":               $secondary,
        "terminal.ansiCyan":                  $info,
        "terminal.ansiWhite":                 $white,
        "focusBorder":                        $primary,
        "selection.background":               $muted,
        "input.background":                   $programBg,
        "input.foreground":                   $fg,
        "input.border":                       $muted,
        "inputOption.activeBorder":           $primary,
        "list.activeSelectionBackground":     $dark,
        "list.activeSelectionForeground":     $fg,
        "list.hoverBackground":               $dark,
        "scrollbarSlider.background":         $muted,
        "scrollbarSlider.hoverBackground":    $primary,
        "button.background":                  $primary,
        "button.foreground":                  $bg,
        "badge.background":                   $primary,
        "badge.foreground":                   $bg,
        "progressBar.background":             $primary
      },
      "editor.tokenColorCustomizations": {
        "textMateRules": [
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
      }
    }' > "$tmp_colors"
  mv "$tmp_colors" "$colors_file"
  log "Rendered VSCode colors → $colors_file"

  # Merge base settings + color settings into the final settings.json.
  # settings.json is NOT owned by home-manager so there is no
  # checkLinkTargets conflict; it is always a plain mutable file.
  local tmp_merged
  tmp_merged=$(mktemp)
  if [[ -e "$base_file" ]]; then
    if ! jq -s '.[0] * .[1]' "$base_file" "$colors_file" > "$tmp_merged"; then
      log_err "Failed to merge base+colors settings; falling back to colors only"
      cp "$colors_file" "$tmp_merged"
    fi
  else
    log_err "settings.base.json not found; rebuild home-manager to regenerate it"
    cp "$colors_file" "$tmp_merged"
  fi
  mv "$tmp_merged" "$settings_file"
  log "Rendered VSCode settings → $settings_file (base + colors merged)"
}
