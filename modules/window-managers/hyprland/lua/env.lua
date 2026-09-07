local home = os.getenv("HOME") or ""

-- Electron / Wayland hint
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Dynamic cursor size detection with fallback to 30
local cursor_size = "30"
local f = io.open(home .. "/.config/xcursor/config.json", "r")
if f then
    local content = f:read("*a")
    f:close()
    local size_match = content:match('"cursorSize"%s*:%s*(%d+)')
    if size_match then
        cursor_size = size_match
    end
end

hl.env("XCURSOR_THEME", "palette-cursor")
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("XCURSOR_PATH", home .. "/.icons:" .. home .. "/.local/share/icons:/usr/share/icons")
