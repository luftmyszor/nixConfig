{ lib, ... }:
{
  options.modules.services.waybar.enable = lib.mkEnableOption "Enable waybar module";
  # Define additional options
}

