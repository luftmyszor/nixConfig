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
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    package = pkgs.vscode-fhs;

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
  home.packages = [ pkgs.nil ];

  # Allow the palette-switcher to replace settings.json with a mutable file
  # at runtime (it adds color customizations on top of the static settings).
  # force = true makes home-manager overwrite it on every rebuild without
  # requiring a backup, so the two never conflict.
  xdg.configFile."Code/User/settings.json".force = true;
}
