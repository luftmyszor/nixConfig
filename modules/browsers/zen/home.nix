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

  # Enable userChrome.css support.
  # zen reads but does not write to user.js, so a home.file symlink is safe.
  home.file.".zen/default/user.js".text = ''
    // Managed by home-manager – do not edit by hand
    // Enable custom user stylesheets so userChrome.css is applied
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';

  # Create the chrome directory and register the profile on first activation.
  # palette-switch writes ~/.zen/default/chrome/userChrome.css at runtime.
  home.activation.zen-profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZEN_DIR="$HOME/.zen"
    CHROME_DIR="$ZEN_DIR/default/chrome"
    PROFILES_INI="$ZEN_DIR/profiles.ini"

    # Ensure the chrome directory exists (palette-switch writes userChrome.css here)
    mkdir -p "$CHROME_DIR"

    # Register the profile only when no profiles.ini exists yet so that
    # any user-created profiles are preserved on subsequent activations.
    if [[ ! -f "$PROFILES_INI" ]]; then
      cat > "$PROFILES_INI" <<'PROFILES_EOF'
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
  '';
}
