{ pkgs }:
let
  myPackages = with pkgs; [
    dotnet-sdk_10
    omnisharp-roslyn
    netcoredbg
    csharprepl
    zsh
  ];
in

pkgs.mkShell {
  packages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix {
      inherit pkgs;
      shellName = "csharp";
      packages = myPackages;
    }}
  '';
}
