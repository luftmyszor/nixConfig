{ pkgs, lib, config, ... }:

let
  moduleLib = import ../../lib/loadModules.nix { inherit lib; };
  username = "luftmyszor";
  homeDirectory = "/home/${username}";
  palette = import ../../modules/themes/palette.nix;

  cssVars = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "  --${name}: ${value};") palette
  );
  

in
{
  #_module.args.palette = palette;
  imports = moduleLib.loadHomeModules ++ moduleLib.loadOptions;

  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";


    sessionVariables = { };
  };
  # Creates palette.json for script use
  home.file."nixTheme/palette.json".text = 
    builtins.toJSON palette;
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

  modules.shells.zsh.enable = true;
  modules.terminals.ghostty.enable = true;
  modules.window-managers.hyprland.enable = true;


  modules.services.quickshell.enable = true;
  modules.services.waybar.enable = false;
  modules.services.wofi.enable = true;
  modules.services.swww.enable = true;

  home.file.".palette/palette.json".text = 
    builtins.toJSON palette;
}
