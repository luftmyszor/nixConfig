{ config, lib, ... }:

let
  cfg = config.modules.editors.arduino;
in
{
  config = lib.mkIf cfg.enable {
    users.users.luftmyszor.extraGroups = [ "dialout" ];
  };
}
