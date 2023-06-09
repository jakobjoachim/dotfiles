local wezterm = require("wezterm")

local config = {
  color_scheme = "ForestBlue",
  enable_tab_bar = false,
  window_decorations = "RESIZE",
  font = wezterm.font({
    family = "Overpass Mono",
    weight = "Bold",
    harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
  }),
  font_size = 15.0,
  native_macos_fullscreen_mode = true,
  keys = {
    {
      key = "n",
      mods = "SHIFT|CTRL",
      action = wezterm.action.ToggleFullScreen,
    },
    {
      key = "d",
      mods = "CMD",
      action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "d",
      mods = "CMD|SHIFT",
      action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "w",
      mods = "CMD",
      action = wezterm.action.CloseCurrentPane({ confirm = false }),
    },
  },
  audible_bell = "Disabled",
}

return config
