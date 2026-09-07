{ lib, ... }:
{
  options.modules.services.awww = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable awww wallpaper daemon";
    };
    image = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = "Path to wallpaper image";
    };
  };
}
