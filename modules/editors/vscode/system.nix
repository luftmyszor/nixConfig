{ config, pkgs, lib, ... }:

let
  cfg = config.modules.editors.vscode;
in lib.mkIf cfg.enable {
    environment.systemPackages = {
    # Add system config
}

