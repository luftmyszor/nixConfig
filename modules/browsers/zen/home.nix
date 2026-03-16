{ config, lib, pkgs, ... }:

let
  cfg = config.modules.browsers.zen;
  zenFlake = builtins.getFlake "github:youwen5/zen-browser-flake";
  system = pkgs.stdenv.hostPlatform.system;
in
lib.mkIf cfg.enable {
  home.packages = [
    zenFlake.packages.${system}.default
  ];
}
