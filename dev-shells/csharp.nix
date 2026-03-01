{ pkgs }:
let
  myPackages = with pkgs; [
    dotnet-sdk
    omnisharp-roslyn
    netcoredbg
    csharprepl
  ];
in

pkgs.mkShell {
  packages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix { inherit pkgs; shellName = "csharp"; packages = myPackages; }}
  '';
}
