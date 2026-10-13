{ lib, ... }:
{
  options.modules.editors.kicad.enable = lib.mkEnableOption "KiCad EDA suite";
}
