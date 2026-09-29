-- Helper function to parse legacy colors.conf dynamically

local function load_colors(file_path)
	local colors = {}
	local expanded_path = os.getenv("HOME") .. "/" .. file_path:gsub("^~/", "")
	local f = io.open(expanded_path, "r")
	if not f then
		return colors
	end
	for line in f:lines() do
		local name, val = string.match(line, "^%s*%$%s*([%w_]+)%s*=%s*(.-)%s*$")
		if name and val then
			colors[name] = val
		end
	end
	f:close()
	return colors
end

local colors = load_colors("~/.config/hypr/colors.conf")

------------------
---- MONITORS ----
------------------
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "auto",
	scale = "1",
})
hl.monitor({
	output = "HDMI-A-1",
	mode = "preferred",
	position = "auto",
	scale = "1.6",
})

------------------
---- GESTURES ----
------------------
-- 3-Finger gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "move" })
hl.gesture({ fingers = 4, direction = "down", action = "close" })
hl.gesture({ fingers = 4, direction = "pinch", action = "fullscreen" })

-- 4-Finger gestures (swipe up/down to toggle scratchpad)
hl.gesture({
	fingers = 4,
	direction = "vertical",
	action = function()
		hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
	end,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("HYPRCURSOR_SIZE", "48")
hl.env("HYPRCURSOR_THEME", "Moga-Neon-Blue")
hl.env("XCURSOR_THEME", "Moga-Neon-Blue")
hl.env("XCURSOR_SIZE", "48")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("VK_DRIVER_FILES", "/usr/share/vulkan/icd.d/nvidia_icd.json")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("env __NV_PRIME_RENDER_OFFLOAD=0 DRI_PRIME=0 quickshell")
	hl.exec_cmd("~/.local/bin/setwall ~/.cache/current_wallpaper.jpg")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd('if [ -n "$HYPR_BLUETOOTH_DEVICE" ]; then bluetoothctl connect "$HYPR_BLUETOOTH_DEVICE"; fi')
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-color-scheme dark")
	hl.exec_cmd("fcitx5 -d")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 1,
		border_size = 3,
		col = {
			active_border = {
				colors = { colors.primary or "rgba(33ccffee)", colors.secondary or "rgba(00ff99ee)" },
				angle = 45,
			},
			inactive_border = colors.surface_container or "rgba(595959aa)",
		},
		resize_on_border = true,
		allow_tearing = false,
	},

	decoration = {
		rounding = 18,
		rounding_power = 4,
		active_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "0xee1a1a1a",
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 3,
			ignore_opacity = true,
			noise = 0,
			brightness = 0.70,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		force_split = 0,
		preserve_split = false,
		smart_split = false,
		smart_resizing = true,
		permanent_direction_override = false,
		special_scale_factor = 1,
		split_width_multiplier = 1.0,
		use_active_for_splits = true,
		default_split_ratio = 1.0,
		split_bias = 0,
		precise_mouse_move = false,
	},

	plugin = {
		-- hyprscrolling = {
		-- 	column_width = 0.7,
		-- 	fullscreen_on_one_column = false,
		-- },
	},

	input = {
		kb_layout = "us",
		kb_options = "ctrl:nocaps",
		follow_mouse = 1,
		sensitivity = 0.9,
		repeat_delay = 210,
		repeat_rate = 50,
		touchpad = {
			natural_scroll = false,
		},
	},

	xwayland = {
		force_zero_scaling = true,
	},
})

-- Custom Curves
hl.curve("overshot", { type = "bezier", points = { { 0.09, 0.9 }, { 0.05, 1.05 } } })

-- Custom Animations
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "overshot", style = "slidehori" })

-- Device specific
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-------------------------------
---- WINDOWS AND WORKSPACES ---
-------------------------------

-- XWayland video bridge fixes
hl.window_rule({
	name = "xwayland-video-bridge-fixes",
	match = { class = "xwaylandvideobridge" },
	no_initial_focus = true,
	no_focus = true,
	no_anim = true,
	no_blur = true,
	max_size = "1 1",
	opacity = 0.0,
})

-- Focus rule
hl.window_rule({
	name = "suppress-focus-xwayland",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Anyrun Blur
hl.layer_rule({ name = "anyrun-blur", match = { namespace = "^anyrun$" }, blur = true, ignore_alpha = 0.5, xray = true })

-- Rofi Blur
hl.layer_rule({ name = "rofi-blur", match = { namespace = "^rofi$" }, blur = true, ignore_alpha = 0.5 })

-- Quickshell Blur & Transparency
hl.layer_rule({ name = "quickshell-blur", match = { namespace = "^quickshell:.*$" }, blur = true, ignore_alpha = 0.25, xray = true })

-- Import Keybindings
require("keybindings")
