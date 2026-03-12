{ pkgs }:
let
  myPackages = with pkgs; [
    nodejs_24
    yarn
    pnpm
    zsh
  ];
in

pkgs.mkShell {
  packages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix { inherit pkgs; shellName = "nodejs"; packages = myPackages; }}
  '';
}


