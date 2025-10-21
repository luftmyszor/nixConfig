{ config, pkgs, lib, ... }:

let
  cfg = config.modules.{{path}};
in lib.mkIf cfg.enable {
    environment.systemPackages = {
    # Add system config
}

