{ config, pkgs, lib, ... }:

let
  enabled = config.modules.services.wofi.enable;
in

{
  # Only install wofi package if enabled
  environment.systemPackages = lib.optional enabled pkgs.wofi;

  # You can add system-wide wofi service or autostart here if you want
}

