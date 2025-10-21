{ pkgs }:
let
  myPackages = with pkgs; [
    gcc
    clang
    cmake
    ninja
    gdb
    lldb
    valgrind
    cppcheck
  ];
in

pkgs.mkShell {
  packages = myPackages;
  shellHook = ''
    ${import ./shell-hook.nix { inherit pkgs; shellName = "cpp"; packages = myPackages; }}
  '';
}

