{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.modules.services.crossmacro.enable =
    mkEnableOption "CrossMacro mouse and keyboard automation service";
}
