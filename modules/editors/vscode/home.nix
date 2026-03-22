{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.editors.vscode;
  qt-qml = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "qt-qml";
    publisher = "TheQtCompany";
    version = "1.13.0";
    sha256 = "sha256-WPzierXLQM+HdVb0XAx80f4Fdd34Vf7WbFzFapr5VHE=";
  };
in
lib.mkIf cfg.enable {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs.overrideAttrs (old: {
      pname = "vscode";
    });

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions =
        (with pkgs.vscode-extensions; [
          formulahendry.code-runner
          # Nix extensions
          bbenoist.nix
          jnoortheen.nix-ide

          # C++ extensions
          ms-vscode.cpptools

          # C# extensions
          ms-dotnettools.vscode-dotnet-runtime
          ms-dotnettools.csharp
          ms-dotnettools.csdevkit

          # Qml extensions
          #qt-qml
        ])
        ++ [ qt-qml ];

    };
  };
  home.packages = [ pkgs.nil ];

  # Before home-manager's checkLinkTargets step, remove settings.json if it
  # is a regular (mutable) file.  This happens on every rebuild after the
  # palette-switcher has replaced the nix-store symlink with a merged mutable
  # file.  Removing it here lets home-manager recreate the managed symlink;
  # the palette-switcher activation (entryAfter writeBoundary) then merges
  # settings.base.json + settings.colors.json back into a mutable settings.json.
  home.activation.removeVscodeMutableSettings = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    settings_json="${config.xdg.configHome}/Code/User/settings.json"
    if [[ -f "$settings_json" && ! -L "$settings_json" ]]; then
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

    };
  };
}
