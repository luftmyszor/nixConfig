{
  config,
  pkgs,
  palette,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;
in
lib.mkIf cfg.enable {
  # Add home config here
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # Nix extentions
        bbenoist.nix
        jnoortheen.nix-ide

        # C++ extentions
        ms-vscode.cpptools

        # C# extentions
        ms-dotnettools.csharp

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

      # optional: some UI tweaks
      userSettings = {
        "editor.formatOnSave" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";

        "qt-qml.qmlls.useQmlImportPathEnvVar" = true;
      };
    };
  };
  home.packages = [ pkgs.nil ];
}
