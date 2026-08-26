{ lib, ... }:
{
  options.modules.browsers.arduino.enable = lib.mkEnableOption "Arduino IDE";
}
