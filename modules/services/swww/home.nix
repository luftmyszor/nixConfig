{ pkgs, config, lib, ... }:
{
  config = lib.mkIf config.modules.services.swww.enable {
    home.packages = [ pkgs.swww ];

    systemd.user.services.swww-daemon = {
      Unit = {
        Description = "swww daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.swww}/bin/swww-daemon";
        Restart = "always";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

