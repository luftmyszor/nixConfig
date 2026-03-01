{ pkgs }:
let
  myPackages = with pkgs; [
    nodejs_24
    yarn
    pnpm
  ];
in

pkgs.mkShell {
  panodejs_25ckages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix { inherit pkgs; shellName = "nodejs"; packages = myPackages; }}
  '';
}


