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

  # Set up the profile structure for both the legacy ~/.zen/ path and the modern
  # XDG ~/.config/zen/ path.  Zen Browser migrated to the XDG location but not
  # all installs will have completed that migration, so we handle both.
  #
  # Per https://docs.zen-browser.app/guides/live-editing the three prefs below
  # are required for userChrome.css to be loaded and for the browser DevTools to
  # be able to inspect / live-edit the browser UI:
  #   toolkit.legacyUserProfileCustomizations.stylesheets – loads userChrome.css
  #   devtools.chrome.enabled                             – enables chrome devtools
  #   devtools.debugger.remote-enabled                   – enables remote debugger
  #
  # user.js is read-only for Zen (it merges into prefs.js on startup), so writing
  # it from an activation script is safe and avoids the single-path limitation of
  # home.file.
  home.activation.zen-profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    setup_zen_profile() {
      local zen_dir="$1"
      local profile_dir="$zen_dir/default"
      local chrome_dir="$profile_dir/chrome"
      local profiles_ini="$zen_dir/profiles.ini"

      mkdir -p "$chrome_dir"

      # Always (re-)write user.js so prefs stay in sync with this config.
      # mkdir -p above already created profile_dir, so this write is safe.
      cat > "$profile_dir/user.js" <<'USER_JS_EOF'
// Managed by home-manager – do not edit by hand
// https://docs.zen-browser.app/guides/live-editing
// Required for userChrome.css to be loaded and for browser DevTools live editing.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
USER_JS_EOF

      # Create profiles.ini only when missing so user-created profiles are
      # preserved across home-manager activations.
      if [[ ! -f "$profiles_ini" ]]; then
        cat > "$profiles_ini" <<'PROFILES_EOF'
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default
IsRelative=1
Path=default
Default=1
PROFILES_EOF
      fi
    }

    # Support both the legacy ~/.zen/ profile root and the XDG ~/.config/zen/ root.
    setup_zen_profile "$HOME/.zen"
    setup_zen_profile "$HOME/.config/zen"
  '';
}
