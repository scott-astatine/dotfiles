#!/bin/bash

# -----------------------------------------------------------------------------
#  QUINKSHELL NATIVE WALLPAPER & MATERIAL YOU COLOR AUTOMATOR
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(realpath "$0")")

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_wallpaper>"
    exit 1
fi

WALLPAPER=$(realpath "$1")
if [ ! -f "$WALLPAPER" ]; then
    echo "Error: File not found: $WALLPAPER"
    exit 1
fi

echo ":: Updating wallpaper path to: $WALLPAPER"
if [ -f "$HOME/.cache/current_wallpaper.jpg" ]; then
    cp "$HOME/.cache/current_wallpaper.jpg" "$HOME/.cache/prev_wallpaper.jpg" 2>/dev/null || true
fi
cp "$WALLPAPER" "$HOME/.cache/current_wallpaper.jpg"

# 1. Update Quickshell config.json
if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.config/quickshell/config.json" ]; then
    jq --arg path "$WALLPAPER" '.background.wallpaperPath = $path' "$HOME/.config/quickshell/config.json" > "$HOME/.config/quickshell/config.json.tmp" && mv "$HOME/.config/quickshell/config.json.tmp" "$HOME/.config/quickshell/config.json"
fi

# 2. Terminate legacy swaybg instances
killall swaybg 2>/dev/null || true
systemctl --user stop swaybg-wallpaper 2>/dev/null || true

# 3. Extract Material You dynamic colors
echo ":: Extracting Material You colors..."
if [ -f "$SCRIPT_DIR/extract_colors.py" ]; then
    python3 "$SCRIPT_DIR/extract_colors.py" "$WALLPAPER"
fi

echo ":: Notifying Quickshell wallpaper engine..."
quickshell ipc call wallpapers apply "$WALLPAPER" 2>/dev/null || true

echo ":: Reloading desktop themes..."
hyprctl reload 2>/dev/null || true
tmux source-file ~/.tmux.conf 2>/dev/null || true

echo ":: Done! Quickshell wallpaper updated and Material You palette applied."
