{ lib, ... }:
{
  options.modules.browsers.zen.enable = lib.mkEnableOption "Zen Browser";
}
