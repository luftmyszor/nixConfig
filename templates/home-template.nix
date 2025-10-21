{ config, pkgs, palette, lib, ... }:

let
  cfg = config.modules.{{path}};
in lib.mkIf cfg.enable {
  # Add home config here
}

