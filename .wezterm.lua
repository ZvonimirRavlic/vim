-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- ~/.wezterm.lua is a symlink into ~/vim; watch the real file so edits reload automatically
wezterm.add_to_config_reload_watch_list(wezterm.home_dir .. "/vim/.wezterm.lua")

-- Let apps that ask for it (herdr, nvim) use the kitty keyboard protocol, so modified keys
-- such as Cmd+Alt+<key> can be told apart. Apps that don't ask (the shell) are unaffected.
config.enable_kitty_keyboard = true

-- Option+n (˜), Option+e (´) ... are dead keys on macOS layouts; they would swallow Cmd+Alt+n
-- and Alt+<key> chords. Inside WezTerm, Option always acts as Alt instead.
config.use_dead_keys = false

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

local function foreground(pane)
	return pane:get_foreground_process_name() or ""
end

local function is_herdr(pane)
	return foreground(pane):find("herdr$") ~= nil
end

-- Send the key to nvim (or to herdr, which passes it on to the nvim pane) when one of them is
-- in the foreground, otherwise run the WezTerm action.
-- nvim_action defaults to sending the key itself; Cmd keys need an explicit CSI-u sequence.
local function nvim_aware(key, mods, fallback, nvim_action)
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			if foreground(pane):find("n?vim$") or is_herdr(pane) then
				win:perform_action(nvim_action or act.SendKey({ key = key, mods = mods }), pane)
			else
				win:perform_action(fallback, pane)
			end
		end),
	}
end

-- Cmd Alt = herdr layer. Forwarded as CSI-u (super+alt, modifier 11) only while herdr runs in the tab.
-- Outside herdr, Cmd Alt h/j/k/l move between WezTerm panes and the rest do nothing.
-- An ordered list, not a table iterated with pairs(): WezTerm numbers action_callback handlers in
-- creation order and evaluates the config more than once, so the order must be the same every time.
-- The CSI-u key code is the character's byte value (h = 104, - = 45, 1 = 49, ...).
local herdr_keys = { "h", "j", "k", "l", "p", "n", "t", "o", "w", "s", "v", "g", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local outside_herdr = {
	h = act.ActivatePaneDirection("Left"),
	j = act.ActivatePaneDirection("Down"),
	k = act.ActivatePaneDirection("Up"),
	l = act.ActivatePaneDirection("Right"),
}

config.keys = {}
for _, key in ipairs(herdr_keys) do
	local code = string.byte(key)
	table.insert(config.keys, {
		key = key,
		mods = "CMD|ALT",
		action = wezterm.action_callback(function(win, pane)
			if is_herdr(pane) then
				win:perform_action(act.SendString("\x1b[" .. code .. ";11u"), pane)
			elseif outside_herdr[key] then
				win:perform_action(outside_herdr[key], pane)
			end
		end),
	})
end

for _, binding in ipairs({
	-- Cmd T in nvim = new terminal tab (arrives as <D-t>)
	nvim_aware("t", "CMD", act.SpawnTab("CurrentPaneDomain"), act.SendString("\x1b[116;9u")),
	-- Cmd W in nvim = close editor/terminal tab (arrives as <D-w>)
	nvim_aware("w", "CMD", act.CloseCurrentTab({ confirm = true }), act.SendString("\x1b[119;9u")),
	-- Always open a new WezTerm tab, even when nvim is running
	{ key = "t", mods = "CMD|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	-- Always switch WezTerm tabs, even when nvim is running
	{ key = "h", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
	{ key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
	-- Esc for herdr: WezTerm sends a bare ESC byte, which herdr can't tell from the start of an Alt
	-- chord, so it holds it back (a tap only works when held). Send the unambiguous kitty form instead.
	{
		key = "Escape",
		mods = "NONE",
		action = wezterm.action_callback(function(win, pane)
			if is_herdr(pane) then
				win:perform_action(act.SendString("\x1b[27u"), pane)
			else
				win:perform_action(act.SendKey({ key = "Escape" }), pane)
			end
		end),
	},
}) do
	table.insert(config.keys, binding)
end

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
