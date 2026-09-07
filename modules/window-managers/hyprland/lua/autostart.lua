-- Autostart services and initial state
hl.on("hyprland.start", function()
    hl.exec_cmd("palette-switch apply")
    hl.exec_cmd("xrdb -merge ~/.Xresources")
end)

-- Startup test command
hl.exec_cmd("echo s")
