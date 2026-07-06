{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "dev" ''
      if [ $# -eq 0 ]; then
        echo -e "\033[1;31mError:\033[0m No shells specified."
        echo "Usage: dev <shell1> [shell2] [shell3] ..."
        echo "Example: dev nix python cpp"
        exit 1
      fi

      FLAKE_PATH="/etc/nixos" 

      CMD=()

      for target in "$@"; do
        CMD+=("nix" "develop" "$FLAKE_PATH#$target" "-c")
      done

      CMD+=("zsh")

      echo -e "\033[1;36mStacking shells: $@...\033[0m"

      exec "''${CMD[@]}"
    '')
  ];
}
