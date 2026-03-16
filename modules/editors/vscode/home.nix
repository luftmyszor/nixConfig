{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;
in
lib.mkIf cfg.enable {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        formulahendry.code-runner
        # Nix extentions
        bbenoist.nix
        jnoortheen.nix-ide

        # C++ extentions
        ms-vscode.cpptools

        # C# extentions
        ms-dotnettools.vscode-dotnet-runtime
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit

        # Qml extentions

      ]
      # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #   {
      #     name = "Qt Qml";
      #     publisher = "Qt Group";
      #     version = "1.9.0";
      #     sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2";
      #   }
      # ]
      ;

      userSettings = {
        "editor.formatOnSave" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";

        "qt-qml.qmlls.useQmlImportPathEnvVar" = true;

        "code-runner.runInTerminal" = true;
        "code-runner.executorMap" = {
          "csharp" = "dotnet run";
        };
      };
    };
  };
  home.packages = [ pkgs.nil ];

  # Allow home-manager to overwrite an existing settings.json (which may have
  # been left as a plain mutable file by the palette-switcher on the previous
  # activation).  On each rebuild home-manager replaces it with a fresh symlink
  # to the static-settings derivation; the palette-switcher activation then
  # reads the symlink, removes it, and writes a mutable file containing both
  # the static settings and the live palette colors.
  xdg.configFile."Code/User/settings.json".force = true;
}
