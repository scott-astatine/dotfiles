---------------------
---- MY PROGRAMS ----
---------------------
local mainMod = "ALT"
local terminal = "/bin/kitty ~/.tmux-manage"
local fileManager = "dolphin"
local menu = "quickshell ipc --any-display call search toggle"
local hyprbrightctl = "/home/scott/.config/hypr/hyprbrightctl.sh"

-- Core Binds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("systemctl reboot"))
hl.bind("Insert", hl.dsp.exec_cmd("quickshell ipc --any-display call lock activate"))

-- System Utilities
hl.bind("F8", hl.dsp.exec_cmd("quickshell ipc --any-display call bluetooth toggle"))
hl.bind("F11", hl.dsp.exec_cmd("quickshell ipc --any-display call audio toggle"))
hl.bind("WIN + S", hl.dsp.exec_cmd("~/.local/bin/shufflewallpaper"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("quickshell ipc --any-display call wifi toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("quickshell ipc --any-display call sidebarRight toggle"))
hl.bind("XF86WLAN", hl.dsp.exec_cmd("quickshell ipc --any-display call wifi toggle"), { locked = true })
hl.bind("XF86RFKill", hl.dsp.exec_cmd("quickshell ipc --any-display call wifi toggle"), { locked = true })
hl.bind("XF86Bluetooth", hl.dsp.exec_cmd("quickshell ipc --any-display call bluetooth toggle"), { locked = true })
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd("hyprpicker -a -f hex"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("quickshell ipc --any-display call search clipboardToggle"))

-- App Shortcuts
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc --any-display call search toggle"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("quickshell ipc --any-display call search toggle"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("antigravity"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.exit())
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("quickshell ipc --any-display call search toggle"))
hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.exec_cmd("killall quickshell || env __NV_PRIME_RENDER_OFFLOAD=0 DRI_PRIME=0 quickshell")
)
hl.bind(
	mainMod .. " + SHIFT + C",
	hl.dsp.exec_cmd([[rofi -show calc -modi calc -no-show-match -no-sort -calc-command "echo -n '{result}' | wl-copy"]])
)

-- Navigation: Move focus with mainMod + HJKL
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Navigation: Move active window with mainMod + SHIFT + HJKL
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Resize windows (Repeating mode enabled)
hl.bind(mainMod .. " + bracketright", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + bracketleft", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })

-- Workspace bindings loop (1-10)
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Dragging / Resizing using Mouse (Mouse flag enabled)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop Multimedia & Brightness controls
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
hl.bind("F10", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(hyprbrightctl .. " +"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(hyprbrightctl .. " -"))

-- Player controls (Requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause -a"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause -a"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
