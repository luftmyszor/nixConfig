local ok, hl = pcall(require, "hyprland")
if not ok then
  return
end

local home = os.getenv("HOME") or ""
local mod = "SUPER"
local terminal = "ghostty"
local wofi_enabled = __ENABLE_WOFI__
local palette_switcher_enabled = __ENABLE_PALETTE_SWITCHER__
local xcursor_enabled = __ENABLE_XCURSOR__
local xcursor_size = "__XCURSOR_SIZE__"

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

local env = {
  "ELECTRON_OZONE_PLATFORM_HINT,auto",
}
if xcursor_enabled then
  table.insert(env, "XCURSOR_THEME,palette-cursor")
  table.insert(env, "XCURSOR_SIZE," .. xcursor_size)
  table.insert(env, "XCURSOR_PATH,$HOME/.icons:$HOME/.local/share/icons:/usr/share/icons")
end

local exec_once = {}
if palette_switcher_enabled then
  table.insert(exec_once, "palette-switch apply")
end
if xcursor_enabled then
  table.insert(exec_once, "xrdb -merge ~/.Xresources")
end

local bind = {
  mod .. ", F, exec, firefox",
  mod .. ", RETURN, exec, " .. terminal,
  mod .. ", M, exec, hyprctl dispatch exit",
  mod .. ", W, exec, hyprctl dispatch killactive",
  mod .. ", Tab, cyclenext,",
  mod .. ", Tab, bringactivetotop,",
  mod .. " SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy",
}
for i = 0, 8 do
  local ws = i + 1
  table.insert(bind, mod .. ", code:1" .. i .. ", workspace, " .. ws)
  table.insert(bind, mod .. " SHIFT, code:1" .. i .. ", movetoworkspace, " .. ws)
end
if wofi_enabled then
  table.insert(bind, mod .. ", R, exec, wofi --show drun -c ~/.config/wofi/config -s ~/.config/wofi/style.css")
end
table.insert(bind, mod .. ",grave, togglespecialworkspace, special:dropdown")

hl.config({
  misc = {
    disable_splash_rendering = "true",
    disable_hyprland_logo = "true",
    vfr = "true",
  },
  env = env,
  monitor = {
    "eDP-1, 1920x1200, auto, 1",
    ", preffered, auto, 1",
  },
  workspace = {
    "s[false], gapsin:30, gapsout:15 15 15 15",
    "special:dropdown, on-created-empty:" .. terminal,
    "s[true], gapsout:0 0 750 0, gapsin:0, border:false",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
  },
  bind = bind,
  binds = {
    drag_threshold = "10",
  },
  bindm = {
    mod .. ", CONTROL_L, movewindow",
    mod .. ", mouse:272, movewindow",
    mod .. ", ALT_L, resizeWindow",
    mod .. ", mouse:273, resizeWindow",
  },
  bindc = {
    mod .. ", mouse:272, togglefloating",
  },
  bindel = {
    ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
    ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+",
    ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%- ",
  },
  exec = {
    "echo s",
  },
  ["exec-once"] = exec_once,
  windowrulev2 = {
    "float,onworkspace: special:dropdown",
    "pin,onworkspace: special:dropdown",
  },
  animation = {
    "specialWorkspace, 1, 4, default, slidefadevert -50%",
  },
  general = {
    ["col.active_border"] = active_border,
    ["col.inactive_border"] = inactive_border,
  },
})
