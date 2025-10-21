{ config, pkgs, lib, ... }:

let cfg = config.modules.terminals.ghostty;
in lib.mkIf cfg.enable {
  environment.systemPackages = [
    pkgs.ghostty
]; 
}
