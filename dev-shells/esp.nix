{ pkgs }:
let
  # ESP32 development relies heavily on Python and pyserial for serial communication
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pyserial
    ]
  );

  myPackages = with pkgs; [
    arduino-cli
    esptool
    espflash
    platformio
    pythonEnv
  ];
in
pkgs.mkShell {
  packages = myPackages;

  shellHook = ''
    ${import ./shell-hook.nix {
      inherit pkgs;
      shellName = "esp";
      packages = myPackages;
    }}
  '';
}
