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
      extensions =
        with pkgs.vscode-extensions;
        [
          formulahendry.code-runner
          # Nix extensions
          bbenoist.nix
          jnoortheen.nix-ide

          # C++ extensions
          ms-vscode.cmake-tools
          ms-vscode.cpptools-extension-pack

          # C# extensions
          ms-dotnettools.vscode-dotnet-runtime
          ms-dotnettools.csharp
          ms-dotnettools.csdevkit

          # Qml extensions

        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            # This installs the bbenoist QML extension dynamically
            name = "QML";
            publisher = "bbenoist";
            version = "1.0.0";
            sha256 = "sha256-tphnVlD5LA6Au+WDrLZkAxnMJeTCd3UTyTN1Jelditk=";
            # Note: If Nix complains about the hash on rebuild,
            # just copy the correct hash it gives you in the error message!
          }
        ];
    };
  };
  home.packages = [ pkgs.nil ];

  # Before home-manager's checkLinkTargets step, remove settings.json if it is
  # a nix-store symlink (legacy from a previous configuration that let
  # home-manager manage it).  Plain mutable files written by the palette-switcher
  # are kept as-is — they have the right colors and can be overwritten in-place.
  home.activation.removeVscodeMutableSettings = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    settings_json="${config.xdg.configHome}/Code/User/settings.json"
    if [[ -L "$settings_json" ]]; then
      rm -f "$settings_json"
    fi
  '';

  # Static (non-color) settings managed by this module.
  #
  # Written to settings.base.json as a nix-store symlink — home-manager never
  # touches settings.json directly, so there is no checkLinkTargets conflict.
  # The palette-switcher activation reads this file as the base, writes the
  # live palette colors to settings.colors.json, and merges them into the
  # final mutable settings.json.
  xdg.configFile."Code/User/settings.base.json" = {
    text = builtins.toJSON {
      "editor.formatOnSave" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";

      "qt-qml.qmlls.useQmlImportPathEnvVar" = true;

      "code-runner.runInTerminal" = true;
      "code-runner.executorMap" = {
        "csharp" = "dotnet run";
        "cpp" = "cd $dir && g++ -std=c++14 *.cpp  -o $fileNameWithoutExt && $dir$fileNameWithoutExt";
      };

      # Disable auto-update and extension update checks (previously set via
      # profiles.default.enableUpdateCheck/enableExtensionUpdateCheck, which caused
      # home-manager to write settings.json as a read-only nix-store symlink and
      # prevented the palette-switcher from hot-reloading colours).
      "update.mode" = "none";
      "extensions.autoCheckUpdates" = false;

    };
  };
}
