{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.window-managers.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";

      extraLuaFiles = {
        "init" = {
          content = ./lua/init.lua;
          autoLoad = false;
        };
        "theme" = {
          content = ./lua/theme.lua;
          autoLoad = false;
        };
        "bindings" = {
          content = ./lua/bindings.lua;
          autoLoad = false;
        };
        "dropdown" = {
          content = ./lua/dropdown.lua;
          autoLoad = false;
        };
        "workspaces" = {
          content = ./lua/workspaces.lua;
          autoLoad = false;
        };
        "autostart" = {
          content = ./lua/autostart.lua;
          autoLoad = false;
        };
        "env" = {
          content = ./lua/env.lua;
          autoLoad = false;
        };
      };

      extraConfig = ''
        -- Clear cached modules so reloading picks up fresh changes
        package.loaded["init"] = nil
        package.loaded["theme"] = nil
        package.loaded["bindings"] = nil
        package.loaded["dropdown"] = nil
        package.loaded["workspaces"] = nil
        package.loaded["autostart"] = nil
        package.loaded["env"] = nil

        local home = os.getenv("HOME") or ""
        local default_dir = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/hypr"
        local config_dir = os.getenv("HYPRLAND_CONFIG_DIR")

        if config_dir and config_dir ~= "" then
            -- Live prototyping from specified nix config path
            package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path
        else
            -- Normal operation using generated files in .config
            package.path = default_dir .. "/?.lua;" .. default_dir .. "/?/init.lua;" .. package.path
        end

        require("init")
      '';
    };
  };
}
