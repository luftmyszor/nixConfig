{ pkgs }:
let
  myPackages = with pkgs; [
    dotnet-sdk_10
    omnisharp-roslyn
    netcoredbg
    csharprepl

    # SkiaSharp deps (provides libfontconfig.so.1 etc.)
    fontconfig
    freetype
    glib
    stdenv.cc.cc.lib

    xorg.libX11
    xorg.libXext
    xorg.libXrender
  ];

  libPath = pkgs.lib.makeLibraryPath myPackages;
in
pkgs.mkShell {
  packages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix {
      inherit pkgs;
      shellName = "csharp";
      packages = myPackages;
    }}

    # Make native libs visible to libSkiaSharp + its deps
    export LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH"
  '';
}
