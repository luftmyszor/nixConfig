{
  config,
  pkgs,
  palette,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;
in
lib.mkIf cfg.enable {
  # Add system config here
  environment.systemPackages = [
    pkgs.vscode-fhs
  ];
}
