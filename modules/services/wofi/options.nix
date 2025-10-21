{ lib, ... }:

with lib;

{
  options.modules.services.wofi.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable the wofi launcher service, install package and configs.";
  };
}

