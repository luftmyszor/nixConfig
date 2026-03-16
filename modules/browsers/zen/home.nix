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
}
