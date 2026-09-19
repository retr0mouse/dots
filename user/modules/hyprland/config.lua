---@module 'hl'

local terminal = "kitty"

local menu = "rofi -show drun"

local browser = "brave"

local screenshot =
	[[grim -g "$(slurp -d -b '#101211cc' -c '#98a87cff' -s '#1a1d1b66' -B '#303630ff' -F 'Iosevka Nerd Font' -w 1)" - | swappy -f -]]

local hyprmoncfg_monitors = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"

local file = io.open(hyprmoncfg_monitors, "r")
if file then
	file:close()
	dofile(hyprmoncfg_monitors)
end
-- Autostart apps

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

-- Enable animations

hl.config({
	animations = {
		enabled = 1,
	},
})

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
})

-- Input config

hl.config({
	input = {
		kb_layout = "ee(us), ru",
		kb_options = "grp:ctrl_space_toggle",
		follow_mouse = 2,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
		},
	},
})

-- General settings

hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 0,
		layout = "dwindle",
		no_focus_fallback = 1,
		col = {
			active_border = "rgba(00000000)",
			inactive_border = "rgba(00000000)",
		},
	},
})

hl.config({
	decoration = {
		shadow = {
			enabled = false,
		},
		rounding = 0,
	},
})

-- Dwindle layout

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	cursor = {
		no_warps = true,
	},
})

-- Window rules

hl.window_rule({
	match = {
		title = "Telegram",
	},
	size = "500 700",
	workspace = "10 silent",
	pseudo = true,
})

hl.window_rule({
	match = {
		title = "Discord",
	},
	workspace = "10 silent",
})

hl.window_rule({
	match = {
		title = "Steam",
	},
	workspace = "9 silent",
})

hl.window_rule({
	match = {
		class = "^steam_app_[0-9]+$",
	},
	workspace = "5 silent",
})

hl.window_rule({
	match = {
		class = "^Minecraft.*$",
	},
	workspace = "5 silent",
})

hl.window_rule({
	match = {
		class = "^(com.saivert.pwvucontrol)$",
	},
	float = true,
	size = "800 600",
	center = true,
})

-- Move and resize windows with mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- ALT + LMB: Move a window
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- ALT + RMB: Resize a window

-- Move windows with keyboard

hl.bind("SUPER + SHIFT" .. " + " .. "H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT" .. " + " .. "J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT" .. " + " .. "K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT" .. " + " .. "L", hl.dsp.window.move({ direction = "r" }))

-- Resize windows using keyboard
-- Switch to a submap called `resize`.
hl.bind("SUPER + R", hl.dsp.submap("resize"))

-- Start a submap called "resize".
hl.define_submap("resize", function()
	-- Set repeating binds for resizing the active window.
	hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })

	-- Use `reset` to go back to the global submap
	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Keybinds further down will be global again...

hl.bind("SUPER" .. " + " .. "Return", hl.dsp.exec_cmd(terminal))

hl.bind("SUPER" .. " + " .. "Space", hl.dsp.exec_cmd(menu))

hl.bind("Pause", hl.dsp.exec_cmd("hyprlock"))

hl.bind("SUPER + SHIFT" .. " + " .. "Return", hl.dsp.exec_cmd(browser))

hl.bind("SUPER + SHIFT" .. " + " .. "Q", hl.dsp.window.close())

hl.bind("SUPER" .. " + " .. "E", hl.dsp.exec_cmd("kitty -e yazi"))

hl.bind("SUPER" .. " + " .. "V", hl.dsp.window.float())

hl.bind("SUPER" .. " + " .. "F", hl.dsp.window.fullscreen())

hl.bind("SUPER" .. " + " .. "P", hl.dsp.window.pseudo())

-- Move focus

hl.bind("SUPER" .. " + " .. "H", hl.dsp.focus({ direction = "left" }))

hl.bind("SUPER" .. " + " .. "L", hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER" .. " + " .. "K", hl.dsp.focus({ direction = "up" }))

hl.bind("SUPER" .. " + " .. "J", hl.dsp.focus({ direction = "down" }))

-- Workspaces

hl.bind("SUPER" .. " + " .. 1, hl.dsp.focus({ workspace = 1 }))

hl.bind("SUPER" .. " + " .. 2, hl.dsp.focus({ workspace = 2 }))

hl.bind("SUPER" .. " + " .. 3, hl.dsp.focus({ workspace = 3 }))

hl.bind("SUPER" .. " + " .. 4, hl.dsp.focus({ workspace = 4 }))

hl.bind("SUPER" .. " + " .. 5, hl.dsp.focus({ workspace = 5 }))

hl.bind("SUPER" .. " + " .. 6, hl.dsp.focus({ workspace = 6 }))

hl.bind("SUPER" .. " + " .. 7, hl.dsp.focus({ workspace = 7 }))

hl.bind("SUPER" .. " + " .. 8, hl.dsp.focus({ workspace = 8 }))

hl.bind("SUPER" .. " + " .. 9, hl.dsp.focus({ workspace = 9 }))

hl.bind("SUPER" .. " + " .. 0, hl.dsp.focus({ workspace = 10 }))

hl.bind("SUPER" .. " + " .. "N", hl.dsp.workspace.toggle_special(nil))

-- Move window to workspace

hl.bind("SUPER + SHIFT" .. " + " .. 1, hl.dsp.window.move({ workspace = 1 }))

hl.bind("SUPER + SHIFT" .. " + " .. 2, hl.dsp.window.move({ workspace = 2 }))

hl.bind("SUPER + SHIFT" .. " + " .. 3, hl.dsp.window.move({ workspace = 3 }))

hl.bind("SUPER + SHIFT" .. " + " .. 4, hl.dsp.window.move({ workspace = 4 }))

hl.bind("SUPER + SHIFT" .. " + " .. 5, hl.dsp.window.move({ workspace = 5 }))

hl.bind("SUPER + SHIFT" .. " + " .. 6, hl.dsp.window.move({ workspace = 6 }))

hl.bind("SUPER + SHIFT" .. " + " .. 7, hl.dsp.window.move({ workspace = 7 }))

hl.bind("SUPER + SHIFT" .. " + " .. 8, hl.dsp.window.move({ workspace = 8 }))

hl.bind("SUPER + SHIFT" .. " + " .. 9, hl.dsp.window.move({ workspace = 9 }))

hl.bind("SUPER + SHIFT" .. " + " .. 0, hl.dsp.window.move({ workspace = 10 }))

hl.bind("SUPER + SHIFT" .. " + " .. "N", hl.dsp.window.move({ workspace = "special" }))

-- Screenshot
hl.bind("SUPER + SHIFT" .. " + " .. "S", hl.dsp.exec_cmd(screenshot))

-- Ignore maximize requests from apps. You'll probably like this.

hl.window_rule({
	name = "suppressevent_maximi",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

-- Laptop multimedia keys for volume and LCD brightness

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true })

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true })

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("waypaper --restore")
end)
