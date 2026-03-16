{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;

  # Static (non-color) settings managed by this module.
  # Written to settings.json every rebuild via home.activation so that
  # home-manager never places a read-only nix-store symlink there — leaving
  # the file mutable for the palette-switcher to merge colors on top.
  staticSettings = pkgs.writeText "vscode-base-settings.json" (
    builtins.toJSON {
      "editor.formatOnSave" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";

      "qt-qml.qmlls.useQmlImportPathEnvVar" = true;

      "code-runner.runInTerminal" = true;
      "code-runner.executorMap" = {
        "csharp" = "dotnet run";
      };
    }
  );
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
  };
  home.packages = [ pkgs.nil ];

  # Write static VSCode settings on every rebuild.  Using an activation script
  # (rather than programs.vscode.userSettings / xdg.configFile) keeps
  # settings.json as a plain mutable file so the palette-switcher can freely
  # merge color customizations on top without fighting home-manager's symlinks.
  #
  # Note: this intentionally overwrites any existing settings.json with the
  # static base each rebuild.  The palette-switcher activation (which lists
  # "vscodeSettings" in its entryAfter) always runs next and re-applies the
  # current palette's color blocks on top, so the final file is always
  # static settings + live palette colors.
  home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_file="$HOME/.config/Code/User/settings.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$settings_file")"
    $DRY_RUN_CMD cp ${staticSettings} "$settings_file"
    $DRY_RUN_CMD chmod 644 "$settings_file"
  '';
}
