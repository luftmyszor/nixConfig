{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.dev.antigravity;
in
lib.mkIf cfg.enable {
  home.packages = [
    pkgs.antigravity-cli
  ];

  programs.zsh.shellAliases = {
    ai = "agy";
  };
}
