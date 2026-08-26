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

  # 1. Install the normal packages
  home.packages = [
    pkgs.unityhub
    pkgs.dotnet-sdk
  ];

  # 2. Force your Desktop Environment to use our custom launch command
  xdg.desktopEntries.unityhub = {
    name = "Unity Hub";
    exec = "env -u GDK_PIXBUF_MODULE_FILE GTK_USE_PORTAL=0 ${pkgs.unityhub}/bin/unityhub %U";
    icon = "unityhub";
    terminal = false;
    categories = [ "Development" ];
    type = "Application";
  };
}
