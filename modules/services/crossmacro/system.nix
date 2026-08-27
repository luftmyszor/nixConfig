{ config, lib, ... }:
let
  cfg = config.modules.services.crossmacro;
in
{
  config = lib.mkIf cfg.enable {
    services.crossmacro = {
      enable = true;
      users = [ "luftmyszor" ];
    };
  };
}
