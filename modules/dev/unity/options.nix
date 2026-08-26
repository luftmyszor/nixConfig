{ lib, ... }:
{
  options.modules.dev.unity.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Unity development environment packages.";
  };
}
