{ lib, ... }:
{
  options.modules.{{path}}.enable = lib.mkEnableOption "Enable {{name}} module";
  # Define additional options
}

