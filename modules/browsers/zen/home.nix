{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.browsers.zen;
  # Locked to the specific commit hash for pure evaluation
  zenFlake = builtins.getFlake "github:0xc000022070/zen-browser-flake/3671c6eceee35fd06fd1f60b71eed968cc9d7449";
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Import using the exact attribute name defined in their flake.nix
  imports = [
    zenFlake.homeModules.default
  ];

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      package = zenFlake.packages.${system}.default;

      profiles.default = {

        isDefault = true;

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # Optional: Sometimes required to allow userChrome to read external file:/// URLs
          "security.fileuri.strict_origin_policy" = false;
        };

        userChrome = ''
          @import url("file:///home/luftmyszor/.config/palettes/palette.css");

          /* Target the main window aggressively to beat Zen's built-in theme engine */
          html#main-window, window#main-window {
            --zen-primary-color: var(--primary) !important;
            --zen-colors-primary: var(--primary) !important;
            --zen-colors-secondary: var(--secondary) !important;
            --zen-colors-tertiary: var(--tertiary) !important;
            
            --zen-colors-bg: var(--bg) !important;
            --zen-colors-fg: var(--fg) !important;
            --zen-colors-border: var(--muted) !important;
          }

          /* --- DIAGNOSTIC TEST --- */
          /* If the file is loading, your top bar will be aggressively red */
          #navigator-toolbox {
            background-color: #ff0000 !important;
          }
        '';
      };
    };
  };
}
