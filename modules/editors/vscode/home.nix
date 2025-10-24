{ config, pkgs, palette, lib, ... }:

let
  cfg = config.modules.editors.vscode;
in lib.mkIf cfg.enable {
  # Add home config here
  programs.vscode = {
    enable = true;
  };
}

