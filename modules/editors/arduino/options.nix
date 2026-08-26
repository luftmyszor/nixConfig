{ lib, ... }:
{
  options.modules.editors.arduino.enable = lib.mkEnableOption "Arduino IDE";
}
