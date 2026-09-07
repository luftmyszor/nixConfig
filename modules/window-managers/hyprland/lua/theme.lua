local M = {}

-- Safe fallback colors in case dynamic palette files are not yet generated
local fallback_palette = {
    bg = "#1a1b26",
    fg = "#c0caf5",
    primary = "#7aa2f7",
    secondary = "#bb9af7",
    tertiary = "#73daca",
    muted = "#343b58",
    danger = "#f7768e",
}

-- Convert "#RRGGBB" or "RRGGBB" to "rgb(RRGGBB)"
local function to_rgb(hex)
    if not hex then return "rgb(ffffff)" end
    local clean = hex:gsub("#", "")
    return "rgb(" .. clean .. ")"
end

local function parse_json(content)
    local palette = {}
    for k, v in content:gmatch('"([%w_-]+)"%s*:%s*"([^"]+)"') do
        palette[k] = v
    end
    return palette
end

local function parse_css(content)
    local palette = {}
    for k, v in content:gmatch('%-%-([%w_-]+)%s*:%s*([^;]+);') do
        palette[k] = v:match('^%s*(.-)%s*$')
    end
    return palette
end

local function parse_lua_palette(content)
    local palette = {}
    for k, v in content:gmatch('([%w_-]+)%s*=%s*"rgb%((%x+)%)"') do
        palette[k] = "#" .. v
    end
    return palette
end

function M.load_palette()
    local home = os.getenv("HOME") or ""
    -- Candidate locations for dynamic palette files
    -- Checked in order so dynamic theme-switcher changes take priority,
    -- falling back to the immutable ~/nixTheme outputs.
    local candidates = {
        { path = home .. "/.config/hypr/palette-colors.lua", parser = parse_lua_palette },
        { path = home .. "/.config/palettes/active.json", parser = parse_json },
        { path = home .. "/.config/theme/palette.json", parser = parse_json },
        { path = home .. "/.cache/theme/current/palette.json", parser = parse_json },
        { path = home .. "/nixTheme/palette.json", parser = parse_json },
        { path = home .. "/nixTheme/palette.css", parser = parse_css },
        { path = home .. "/.config/theme/palette.css", parser = parse_css },
    }

    local palette = {}
    for _, candidate in ipairs(candidates) do
        local f = io.open(candidate.path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local parsed = candidate.parser(content)
            if parsed and parsed.primary then
                palette = parsed
                break
            end
        end
    end

    -- Fill missing keys from the fallback palette
    for k, v in pairs(fallback_palette) do
        if not palette[k] then
            palette[k] = v
        end
    end

    return {
        raw = palette,
        bg = to_rgb(palette.bg),
        fg = to_rgb(palette.fg),
        primary = to_rgb(palette.primary),
        secondary = to_rgb(palette.secondary),
        tertiary = to_rgb(palette.tertiary),
        muted = to_rgb(palette.muted),
        danger = to_rgb(palette.danger),
    }
end

function M.apply()
    local colors = M.load_palette()
    hl.config({
        general = {
            col = {
                active_border = {
                    colors = { colors.primary, colors.secondary },
                    angle = 45,
                },
                inactive_border = colors.muted,
            },
        },
    })
end

return M
