{ config, pkgs, lib, palette, ... }:

let 
  moduleLib = import ../../lib/loadModules.nix { inherit lib; };
in
{
  imports = moduleLib.loadSystemModules ++ moduleLib.loadOptions ++ [ 
      ./hardware-configuration.nix
  ];




  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixmyszor"; # Define your hostname.

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };
  
  nix.settings.experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

  };

  users.users.luftmyszor = {
    isNormalUser = true;
    description = "luftmyszor";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
     
    
  };


  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  neovim
  wget
  tree
  fastfetch
  wl-clipboard
  brightnessctl
  gimp3-with-plugins
  inkscape-with-extensions
  gh
  git
  vim
  jq
  ];

  modules.shells.zsh.enable = true;
  modules.terminals.ghostty.enable = true;
  modules.window-managers.hyprland.enable = true;

  modules.services.quickshell.enable = true;
  modules.services.waybar.enable = false;
  modules.services.swww.enable = true; 
  modules.services.wofi.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;


  system.stateVersion = "25.05";

}

