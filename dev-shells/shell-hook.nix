{ pkgs, shellName ? "dev", packages ? [] }:

let
  # ANSI codes (escaped properly for Bash)
  colors = {
    red     = "\\033[1;31m";
    green   = "\\033[1;32m";
    yellow  = "\\033[1;33m";
    blue    = "\\033[1;34m";
    magenta = "\\033[1;35m";
    cyan    = "\\033[1;36m";
    reset   = "\\033[0m";
  };

  ps1Wrap = c: "\\[${c}\\]";

  pkgName = p: if builtins.isString p then p else
              if builtins.hasAttr "pname" p then p.pname else
              let drv = builtins.tryEval p.name; in
              if drv.success then drv.value else "unknown";

  devShellsScriptsPath = toString ./scripts;

in
''
export PATH=$PATH:${devShellsScriptsPath}/${shellName}
export PS1="${ps1Wrap colors.blue}[${ps1Wrap colors.red}${shellName}${ps1Wrap colors.blue} dev shell ${ps1Wrap colors.green}\w${ps1Wrap colors.blue}]${ps1Wrap colors.red}$ ${colors.reset}"

echo -e "${colors.green}Welcome to your ${colors.red}${shellName}${colors.green} dev shell${colors.reset}"
echo -e "${colors.green}User: ${colors.yellow}$USER${colors.reset}"
echo -e "${colors.green}Shell: ${colors.yellow}$(basename "$SHELL")${colors.reset}"
echo -e "Run ${colors.red}shell-pkgs${colors.reset} to list all shell-related packages"

shell-pkgs() {
  echo "Packages in this shell:"
  for pkg in ${builtins.concatStringsSep " " (map pkgName packages)}; do
    echo -e " ${colors.red}- ${colors.reset}$pkg"
  done
}
''

