{ pkgs, config, lib, ... }:
{
  config = lib.mkIf config.modules.services.awww.enable {
    home.packages = [ pkgs.awww ];

    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
