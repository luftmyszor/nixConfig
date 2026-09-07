{ lib, ... }:
{
  options.modules.dev.antigravity.enable = lib.mkEnableOption "Enable Google Antigravity CLI";
}
