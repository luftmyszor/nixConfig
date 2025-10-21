{ config, pkgs, palette, lib, ... }:

let
  cfg = config.modules.services.quickshell;
in lib.mkIf cfg.enable {
  # Add system config here
  environment.systemPackages = [
    pkgs.quickshell
  ];
}

