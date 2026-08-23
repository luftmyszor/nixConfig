{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.editors.arduino;

  # Create a custom Wayland-wrapped version of the IDE
  arduinoWayland = pkgs.symlinkJoin {
    name = "arduino-ide-wayland";
    paths = [ pkgs.arduino-ide ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/arduino-ide \
        --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
        --add-flags "--ozone-platform=wayland"
    '';
  };

  # ESP32 development relies heavily on Python and pyserial for serial communication
  pyserial = pkgs.python3.withPackages (
    ps: with ps; [
      pyserial
    ]
  );

in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      arduinoWayland
      pyserial
    ];
  };
}
