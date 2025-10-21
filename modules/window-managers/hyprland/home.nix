{ config, pkgs, lib, ... }:


let cfg = config.modules.window-managers.hyprland;
in {
  imports = [
    ./configuration/bindings.nix
    ./configuration/exec.nix
    ./configuration/dropdownTerm.nix
    ./configuration/workspace.nix
  ];
  config = lib.mkIf cfg.enable {

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        "$mod" = "SUPER";
        "$terminal" = "ghostty";


        misc = {
          "disable_splash_rendering" = "true";
          "disable_hyprland_logo" = "true";
          "vfr" = "true";
        };


        monitor = [
          ", 1920x1200, auto, 1"
        ];

        workspace = [

        ]
        ++ (
          builtins.concatLists (builtins.genList
            (i:
              let ws = i + 1;
              in [
                "${toString i}"
              ]
            ) 9)
        );

      };
    };
  };
}
