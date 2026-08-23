{ config, lib, ... }:

let
  cfg = config.modules.editors.arduino;
in
{
  config = lib.mkIf cfg.enable {
    # Replace 'yourUsername' with your actual NixOS user name variable
    users.users.luftmyszor.extraGroups = [ "dialout" ];
  };
}
