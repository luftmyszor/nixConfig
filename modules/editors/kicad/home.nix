{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.editors.kicad;
in
lib.mkIf cfg.enable {
  home.packages = [
    pkgs.kicad
  ];
}
