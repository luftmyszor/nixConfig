{ lib, ... }:
{
  options.modules.editors.aseprite.enable = lib.mkEnableOption "Enable Aseprite pixel art editor";
}
