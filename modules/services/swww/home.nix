{
  pkgs,
  config,
  lib,
  ...
}:

let
  pkg = pkgs.awww;
  swwwCompat = pkgs.writeShellScriptBin "swww" ''exec ${pkg}/bin/awww "$@"'';
  swwwDaemonCompat = pkgs.writeShellScriptBin "swww-daemon" ''exec ${pkg}/bin/awww-daemon "$@"'';
in
{
  config = lib.mkIf config.modules.services.swww.enable {
    home.packages = [
      pkg
      swwwCompat
      swwwDaemonCompat
    ];

    systemd.user.services.swww-daemon = {
      Unit = {
        Description = "swww/awww wallpaper daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkg}/bin/awww-daemon";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
