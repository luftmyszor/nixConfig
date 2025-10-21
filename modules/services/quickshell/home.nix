{ config, pkgs, palette, lib, ... }:

let
  cfg = config.modules.services.quickshell;
  quickshellConfig = ./configuration;
in lib.mkIf cfg.enable {
  # Add home config here
  home.packages = [
    pkgs.quickshell
  ];

  home.file.".config/quickshell" = {
    source = quickshellConfig;
    recursive = true;
  };
}

