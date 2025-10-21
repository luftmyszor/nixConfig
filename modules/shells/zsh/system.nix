{ config, pkgs, lib, ... }:

let cfg = config.modules.shells.zsh;
in lib.mkIf cfg.enable {
  programs.zsh.enable = true;
  users.users.luftmyszor.shell = pkgs.zsh;
}

