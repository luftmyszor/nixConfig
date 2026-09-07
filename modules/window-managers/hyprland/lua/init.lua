-- Automatically add the directory of this file to package.path
-- This ensures sibling modules (theme, bindings, dropdown, etc.) are always found,
-- whether running from the immutable Nix store or live prototyping from the repo.
local source = debug.getinfo(1, "S").source
local current_dir = source:match("^@?(.*)/[^/]+$")
if current_dir and current_dir ~= "" then
    package.path = current_dir .. "/?.lua;" .. current_dir .. "/?/init.lua;" .. package.path
end

-- Monitors
hl.monitor({
    output = "eDP-1",
    mode = "1920x1200",
    position = "auto",
    scale = 1,
})
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- General & Misc configuration
hl.config({
    misc = {
        disable_splash_rendering = true,
        disable_hyprland_logo = true,
    },
    debug = {
        vfr = true,
    },
    binds = {
        drag_threshold = 10,
    },
})

-- Load submodules
require("env")
require("theme").apply()
require("workspaces")
require("dropdown")
require("bindings")
require("autostart")
