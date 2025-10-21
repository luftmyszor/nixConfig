{ lib, ... }:
{
  options.modules.terminals.ghostty.enable = lib.mkEnableOption "Enable ghostty terminal emulator";
}

