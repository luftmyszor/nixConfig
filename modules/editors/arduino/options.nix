{ lib, ... }:

with lib;
{
  options.modules.editors.arduino = {
    enable = mkEnableOption "Enable Arduino IDE for ESP32 development";
  };
}
