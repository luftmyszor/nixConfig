{ pkgs }:
let
  myPackages = with pkgs; [
    nixpkgs-fmt
    statix
    deadnix
    nil
    nvd
    nix-diff
    nix-tree
    nix-output-monitor
  ];
in

pkgs.mkShell {
  packages = myPackages;

  shellHook = ''
    ${import ./shell-hook.nix {
      inherit pkgs;
      shellName = "nix";
      packages = myPackages;
    }}
  '';
}
