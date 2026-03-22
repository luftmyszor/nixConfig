{ config, lib, pkgs, ... }:

let
  cfg = config.modules.browsers.zen;
  zenFlake = builtins.getFlake "github:youwen5/zen-browser-flake/c7cb51b30960757ed9fb8eb28567b32585d0a688";
  system = pkgs.stdenv.hostPlatform.system;
in
lib.mkIf cfg.enable {
  home.packages = [
    zenFlake.packages.${system}.default
  ];

  # ── Live theming setup ─────────────────────────────────────────────────────
  # For each existing Zen profile, enable userChrome.css support (via user.js)
  # and create a chrome/userChrome.css that imports the runtime-generated
  # zen-palette.css file written by `palette-switch` (render_zen).
  # Note: run `palette-switch apply` once after Zen creates its first profile.
  home.activation.zen-live-theming = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zen_dir="$HOME/.zen"
    if [[ -d "$zen_dir" ]]; then
      for profile_dir in "$zen_dir"/*/; do
        [[ -d "$profile_dir" ]] || continue
        chrome_dir="$profile_dir/chrome"
        $DRY_RUN_CMD mkdir -p "$chrome_dir"

        # Enable userChrome.css stylesheets if not already set
        user_js="$profile_dir/user.js"
        if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$user_js" 2>/dev/null; then
          echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
            | $DRY_RUN_CMD tee -a "$user_js" > /dev/null
        fi

        # Create userChrome.css importing the palette file (only if absent)
        user_chrome="$chrome_dir/userChrome.css"
        if [[ ! -f "$user_chrome" ]]; then
          _zen_chrome_tmp=$(mktemp)
          cat > "$_zen_chrome_tmp" <<'CSS_EOF'
/* Zen Browser live theme – managed by palette-switch (render_zen).
   Do not add manual styles here; put them in a separate file and
   @import it below so palette-switch can regenerate zen-palette.css
   without losing your customisations. */
@import "zen-palette.css";
CSS_EOF
          $DRY_RUN_CMD cp "$_zen_chrome_tmp" "$user_chrome"
          rm -f "$_zen_chrome_tmp"
        fi
      done
    fi
  '';
}
