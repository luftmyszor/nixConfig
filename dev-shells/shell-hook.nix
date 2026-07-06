{
  pkgs,
  shellName ? "dev",
  packages ? [ ],
}:

let
  # ANSI codes (escaped properly for Bash)
  colors = {
    red = "\\033[1;31m";
    green = "\\033[1;32m";
    yellow = "\\033[1;33m";
    blue = "\\033[1;34m";
    magenta = "\\033[1;35m";
    cyan = "\\033[1;36m";
    reset = "\\033[0m";
  };

  ps1Wrap = c: "\\[${c}\\]";

  pkgName =
    p:
    if builtins.isString p then
      p
    else if builtins.hasAttr "pname" p then
      p.pname
    else
      let
        drv = builtins.tryEval p.name;
      in
      if drv.success then drv.value else "unknown";

  devShellsScriptsPath = toString ./scripts;

in
''
  # 1. Stack the shell names
  if [ -z "$NIX_ACTIVE_SHELLS" ]; then
    export NIX_ACTIVE_SHELLS="${shellName}"
  else
    # Prevent duplicates just in case
    if [[ "$NIX_ACTIVE_SHELLS" != *"${shellName}"* ]]; then
      export NIX_ACTIVE_SHELLS="$NIX_ACTIVE_SHELLS+${shellName}"
    fi
  fi

  # 2. Stack the packages
  if [ -z "$NIX_ACTIVE_PKGS" ]; then
    export NIX_ACTIVE_PKGS="${builtins.concatStringsSep " " (map pkgName packages)}"
  else
    export NIX_ACTIVE_PKGS="$NIX_ACTIVE_PKGS ${builtins.concatStringsSep " " (map pkgName packages)}"
  fi
''
