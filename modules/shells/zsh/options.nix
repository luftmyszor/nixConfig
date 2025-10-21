{ lib, ... }:
{
  options.modules.shells.zsh.enable = lib.mkEnableOption "Enable Zsh module";
}

