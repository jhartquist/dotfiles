local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Gruvbox Dark (Gogh)"
-- hard-contrast background (#1d2021, like the old GruvboxDarkHard) — matches
-- nvim's gruvbox contrast="hard"; the Gogh scheme's own bg is a lighter #282828
config.colors = { background = "#1d2021" }

-- Berkeley Mono is licensed — installed from ~/private/fonts by rebuild.sh,
-- never committed. Falls back to Hack (nix) for symbols and font-less machines.
config.font = wezterm.font_with_fallback({ "Berkeley Mono", "Hack Nerd Font" })

config.font_size = 15.0
config.window_background_opacity = 0.80
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- RESIZE decorations drop the green button, so bind the standard macOS
-- fullscreen shortcut. Non-native = instant borderless overlay, no Space.
config.keys = {
	{ key = "f", mods = "CTRL|CMD", action = wezterm.action.ToggleFullScreen },
}

return config
