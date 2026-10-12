-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 19

config.enable_tab_bar = true

config.window_decorations = "RESIZE"
config.window_background_opacity = 1
config.macos_window_background_blur = 10

--config.color_scheme = "Catppuccin Mocha"

--config.color_scheme = "Catppuccin Macchiato"

-- Same background as nvim's gruvbox (contrast = "hard"), so no strip shows around nvim
config.color_scheme = "Gruvbox dark, hard (base16)"

config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 999
local act = wezterm.action

-- Send the key to nvim when it is in the foreground, otherwise run the WezTerm action.
-- nvim_action defaults to sending the key itself; Cmd keys need an explicit CSI-u sequence.
local function nvim_aware(key, mods, fallback, nvim_action)
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			local proc = pane:get_foreground_process_name() or ""
			if proc:find("n?vim$") then
				win:perform_action(nvim_action or act.SendKey({ key = key, mods = mods }), pane)
			else
				win:perform_action(fallback, pane)
			end
		end),
	}
end

config.keys = {
	-- Cmd T in nvim = new terminal tab (arrives as <D-t>)
	nvim_aware("t", "CMD", act.SpawnTab("CurrentPaneDomain"), act.SendString("\x1b[116;9u")),
	-- Cmd W in nvim = close editor/terminal tab (arrives as <D-w>)
	nvim_aware("w", "CMD", act.CloseCurrentTab({ confirm = true }), act.SendString("\x1b[119;9u")),
	-- Always switch WezTerm tabs, even when nvim is running
	{ key = "h", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
	{ key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
}
function get_max_cols(window)
	local tab = window:active_tab()
	local cols = tab:get_size().cols
	return cols
end

wezterm.on("window-config-reloaded", function(window)
	wezterm.GLOBAL.cols = get_max_cols(window)
end)

wezterm.on("window-resized", function(window, pane)
	wezterm.GLOBAL.cols = get_max_cols(window)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.active_pane.title
	local full_title = "[" .. tab.tab_index + 1 .. "] " .. title
	local pad_length = (wezterm.GLOBAL.cols // #tabs - #full_title) // 2
	if pad_length * 2 + #full_title > max_width then
		pad_length = (max_width - #full_title) // 2
	end
	return string.rep(" ", pad_length) .. full_title .. string.rep(" ", pad_length)
end)
return config
