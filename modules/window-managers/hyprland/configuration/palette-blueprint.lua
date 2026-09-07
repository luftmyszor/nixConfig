local ok, hl = pcall(require, "hyprland")
if not ok then
  return
end

local home = os.getenv("HOME") or ""

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

local function parse_palette_css(content)
  local palette = {}
  for key, value in content:gmatch("%-%-([%w_]+)%s*:%s*([^;]+);") do
    palette[key] = value:gsub("^%s+", ""):gsub("%s+$", "")
  end
  return palette
end

local function parse_palette_json(content)
  local palette = {}
  for key, value in content:gmatch('"([%w_]+)"%s*:%s*"(#?[%x]+)"') do
    palette[key] = value
  end
  return palette
end

local function load_palette()
  local candidates = {
    { path = home .. "/nixTheme/palette.json", parser = parse_palette_json },
    { path = home .. "/nixTheme/palette.css", parser = parse_palette_css },
    { path = home .. "/.config/theme/palette.json", parser = parse_palette_json },
    { path = home .. "/.config/theme/palette.css", parser = parse_palette_css },
    { path = home .. "/.config/palettes/active.json", parser = parse_palette_json },
  }

  for _, candidate in ipairs(candidates) do
    local content = read_file(candidate.path)
    if content then
      local parsed = candidate.parser(content)
      if parsed and next(parsed) ~= nil then
        return parsed
      end
    end
  end

  return {}
end

local function as_hypr_rgb(palette, key, fallback_hex)
  local raw = palette[key] or fallback_hex
  local no_hash = raw:gsub("^#", "")
  return "rgb(" .. no_hash .. ")"
end

local palette = load_palette()
local active_border = as_hypr_rgb(palette, "primary", "ffffff")
  .. " "
  .. as_hypr_rgb(palette, "secondary", "ffffff")
  .. " 45deg"
local inactive_border = as_hypr_rgb(palette, "muted", "888888")

hl.config({
  general = {
    ["col.active_border"] = active_border,
    ["col.inactive_border"] = inactive_border,
  },
})
