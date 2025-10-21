{ lib, ... }:
{
  options.modules.services.swww = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable swww wallpaper daemon";
    };
    image = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = "Path to wallpaper image";
    };
  };
}

