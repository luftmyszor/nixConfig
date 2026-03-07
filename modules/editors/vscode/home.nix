{
  config,
  pkgs,
  palette,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;

  # Extension version – keep in sync with paletteExtVersion in
  # modules/themes/palette-switcher/home.nix.
  paletteExtVersion = "0.0.1";

  # Manifest for the generated Palette Dark theme extension.
  # The actual color data is written at runtime by palette-switch.
  paletteExtensionManifest = builtins.toJSON {
    name = "palette-theme";
    displayName = "Palette Theme";
    version = paletteExtVersion;
    publisher = "palette-switcher";
    engines = { vscode = "^1.0.0"; };
    categories = [ "Themes" ];
    contributes = {
      themes = [
        {
          label = "Palette Dark";
          uiTheme = "vs-dark";
          path = "./themes/palette-dark.json";
        }
      ];
    };
  };
in
lib.mkIf cfg.enable {
  # Deploy the extension manifest so VSCode recognises "Palette Dark".
  # The themes/palette-dark.json color file is generated at runtime by
  # the palette-switch script and is intentionally not managed here.
  home.file.".vscode/extensions/palette-theme-${paletteExtVersion}/package.json".text =
    paletteExtensionManifest;

  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    package = pkgs.vscode-fhs;

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

      # Use the palette-generated theme (colors written by palette-switch).
      "workbench.colorTheme" = "Palette Dark";
    };
  };
  home.packages = [ pkgs.nil ];
}
