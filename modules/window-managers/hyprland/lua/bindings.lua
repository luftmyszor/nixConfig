local mod = "SUPER"
local terminal = "ghostty"

-- Application launches and basic window control
hl.bind(mod .. " + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + Tab", hl.dsp.window.cycle_next())
hl.bind(mod .. " + Tab", hl.dsp.window.bring_to_top())
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

-- App menu (wofi)
hl.bind(mod .. " + R", hl.dsp.exec_cmd("wofi --show drun -c ~/.config/wofi/config -s ~/.config/wofi/style.css"))

-- Workspaces 1-9 (keys 1-9 correspond to keycodes code:10 through code:18)
for i = 1, 9 do
    local code = "code:" .. (i + 9)
    hl.bind(mod .. " + " .. code, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }))
end

-- Mouse bindings
hl.bind(mod .. " + CONTROL_L", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + ALT_L", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse:272", hl.dsp.window.float({ action = "toggle" }), { click = true, mouse = true })

-- Media keys (Volume & Brightness)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
