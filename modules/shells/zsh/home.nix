{ config, pkgs, lib, ... }:

let 
  cfg = config.modules.shells.zsh;
in lib.mkIf cfg.enable {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ 
      "git"
      ];
      theme = "agnoster";
    };
  }; 
}

