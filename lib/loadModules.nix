
{ lib }:

let
  modulesDir = ../modules;

  # Recursively find files like home.nix, system.nix, etc.
  findAndImport = type:
    lib.unique (map (file: import file)
      (lib.filter
        (f: lib.hasSuffix "/${type}.nix" (toString f))
        (lib.filesystem.listFilesRecursive modulesDir)));
in {
  loadHomeModules   = findAndImport "home";
  loadSystemModules = findAndImport "system";
  loadOptions       = findAndImport "options";
}

