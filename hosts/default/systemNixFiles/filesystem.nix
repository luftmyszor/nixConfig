{
  fileSystems."/etc/nixos" = {
    device = "/home/luftmyszor/nixos-flake";
    fsType = "none";
    options = [ "bind" ];
  };
}
