{ pkgs }:
let
  pythonPackages = pypkgs:[
    pypkgs.pip
    pypkgs.numpy
    pypkgs.requests
    pypkgs.pillow
  ];

pythonEnv = pkgs.python312.withPackages pythonPackages;
packageNames = builtins.map (p: p.pname or (builtins.parseDrvName p.name).name)
    (pythonPackages pkgs.python312.pkgs);

in
pkgs.mkShell {
  packages = [ pythonEnv ];  
  shellHook = ''
    ${import ./shell-hook.nix { inherit pkgs; shellName = "python"; packages = packageNames; }}
  '';
}

