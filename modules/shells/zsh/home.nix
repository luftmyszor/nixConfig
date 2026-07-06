{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.shells.zsh;
in
lib.mkIf cfg.enable {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "agnoster";
    };

    shellAliases = {
      # OS Rebuilds (automatically targeting the current machine)
      nixSwitch = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      nixTest = "sudo nixos-rebuild test --flake /etc/nixos#$(hostname)";
    };

    initContent = ''
      # If we are inside a Nix dev shell...
      if [ -n "$NIX_ACTIVE_SHELLS" ]; then
        
        # 1. Recreate the shell-pkgs function natively in Zsh
        function shell-pkgs() {
          echo -e "\033[1;32mPackages loaded from [ \033[1;31m$NIX_ACTIVE_SHELLS \033[1;32m]:\033[0m"
          # The $= syntax tells Zsh to split the string by spaces
          for pkg in $=NIX_ACTIVE_PKGS; do 
            echo -e " \033[1;34m-\033[0m $pkg"
          done
        }

        # 2. Add the active shells to the RIGHT prompt (RPROMPT)
        # Using RPROMPT is safer because it won't break any custom themes you use on the left
        RPROMPT="%F{cyan}[%F{green}dev: %F{red}''${NIX_ACTIVE_SHELLS}%F{cyan}]%f $RPROMPT"
        
        # Print a quick welcome message
        echo -e "\033[1;32mLoaded dev environments:\033[0m \033[1;31m$NIX_ACTIVE_SHELLS\033[0m"
      fi
    '';
  };
}
