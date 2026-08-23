{ config, pkgs, lib, ... }:

let
  cfg = config.modules.editors.aseprite;
in
lib.mkIf cfg.enable {
  home.packages = [ pkgs.aseprite ];
}
