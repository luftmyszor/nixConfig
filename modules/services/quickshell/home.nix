{
  config,
  pkgs,
  palette,
  lib,
  ...
}:

let
  cfg = config.modules.services.quickshell;
  quickshellConfig = ./configuration;
in
lib.mkIf cfg.enable {
  # Add home config here
  home.packages = [
    # Instead of just `pkgs.quickshell`, we create a wrapper script
    # that forces the environment variable every time it runs.
    (pkgs.writeShellScriptBin "quickshell" ''
      export QML_XHR_ALLOW_FILE_READ=1
      exec ${pkgs.quickshell}/bin/quickshell "$@"
    '')
  ];

  home.file.".config/quickshell" = {
    source = quickshellConfig;
    recursive = true;
  };
}
