{ lib, ... }:
{
  options.modules.editors.vscode.enable = lib.mkEnableOption "Enable vscode module";
  # Define additional options
}
