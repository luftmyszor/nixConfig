{
  pkgs,
  lib,
  config,
  ...
}:

let
  moduleLib = import ../../lib/loadModules.nix { inherit lib; };
  username = "luftmyszor";
  homeDirectory = "/home/${username}";
  palette = import ../../modules/themes/palette.nix;

  cssVars = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "  --${name}: ${value};") palette
  );

  # ── theme-switch: live theme switcher driven by the palette catalogue ──────
  # Wraps bin/theme-switch so that jq is always on PATH when the script runs.
  themeSwitchScript = pkgs.writeShellApplication {
    name = "theme-switch";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ../../bin/theme-switch;
  };

in
{
  #_module.args.palette = palette;
  imports =
    moduleLib.loadHomeModules
    ++ moduleLib.loadOptions
    ++ [
      ./settings.nix
    ];

  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";

    sessionVariables = { };
  };
  # Creates palette.json for script use
  home.file."nixTheme/palette.json".text = builtins.toJSON palette;
  home.file."nixTheme/palette.css".text = ''
    :root {
    ${cssVars}
    }

    window {
      background-color: var(--bg);
      color: var(--fg);
      border-radius: 12px;
      padding: 10px;
    }

    #input {
      background-color: var(--programBg);
      border-radius: 8px;
      padding: 6px;
    }

    #entry:selected {
      background-color: var(--primary);
      color: var(--bg);
    }
  '';

  programs.home-manager.enable = true;

  # Make theme-switch available on PATH.
  home.packages = [ themeSwitchScript ];

  # ── Stable out-of-store symlinks + mutable cache seed ─────────────────────
  # ~/.config/theme/{palette.json,palette.css} are stable symlinks that always
  # point into the mutable cache directory.  Apps read from ~/.config/theme/
  # and the cache is updated at runtime by `theme-switch <name>` without any
  # Nix rebuild.
  home.activation.theme-cache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Ensure mutable directories exist
    $DRY_RUN_CMD mkdir -p "$HOME/.cache/theme/current"
    $DRY_RUN_CMD mkdir -p "$HOME/.config/theme"

    # Create / refresh the stable config symlinks (out-of-store targets).
    $DRY_RUN_CMD ln -sfn "$HOME/.cache/theme/current/palette.json" \
                         "$HOME/.config/theme/palette.json"
    $DRY_RUN_CMD ln -sfn "$HOME/.cache/theme/current/palette.css" \
                         "$HOME/.config/theme/palette.css"

    # Seed the cache from build-time palette outputs on first activation so
    # that apps have valid files before `theme-switch` is ever called.
    for ext in json css; do
      src="$HOME/nixTheme/palette.$ext"
      dst="$HOME/.cache/theme/current/palette.$ext"
      if [[ ! -f "$dst" ]] && [[ -f "$src" ]]; then
        $DRY_RUN_CMD cp "$src" "$dst"
      fi
    done
  '';

  home.file.".palette/palette.json".text = builtins.toJSON palette;
}
