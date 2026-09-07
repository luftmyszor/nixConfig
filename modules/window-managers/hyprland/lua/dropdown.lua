local mod = "SUPER"
local terminal = "ghostty"

-- Special dropdown workspace rule
hl.workspace_rule({
    workspace = "special:dropdown",
    on_created_empty = terminal,
})

-- Workspace geometry & border
hl.workspace_rule({
    workspace = "s[true]",
    gaps_out = { top = 0, right = 0, bottom = 750, left = 0 },
    gaps_in = 0,
    no_border = true,
})

-- Dropdown window rules
hl.window_rule({
    match = { workspace = "special:dropdown" },
})

-- Toggle dropdown keybinding
hl.bind(mod .. " + grave", hl.dsp.workspace.toggle_special("dropdown"))

-- Dropdown animation
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 4,
    bezier = "default",
    style = "slidefadevert -50%",
})
