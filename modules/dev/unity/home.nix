{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.dev.unity;
in
lib.mkIf cfg.enable {
  home.packages = [
    pkgs.unityhub
    pkgs.dotnet-sdk
  ];
}
