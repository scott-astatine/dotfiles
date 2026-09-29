#!/usr/bin/env python3
import sys
import os
import colorsys
from PIL import Image

def rgb_to_hex(rgb):
    return f"{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_colors.py <path_to_wallpaper>")
        sys.exit(1)

    wallpaper = os.path.expanduser(sys.argv[1])
    if not os.path.exists(wallpaper):
        print(f"Error: Wallpaper file not found: {wallpaper}", file=sys.stderr)
        sys.exit(1)

    try:
        img = Image.open(wallpaper)
        img = img.convert('RGB')
        # Resize to 100x100 to speed up processing
        img = img.resize((100, 100))
        
        # Quantize to 16 colors
        quantized = img.quantize(colors=16, method=Image.Quantize.MEDIANCUT)
        palette = quantized.getpalette()
        
        # Count frequency of each color to find the most dominant
        color_counts = quantized.getcolors()
        
        # Parse colors and associate them with their counts
        unique_colors = []
        for count, index in color_counts:
            r = palette[3*index]
            g = palette[3*index+1]
            b = palette[3*index+2]
            rgb = (r, g, b)
            h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
            unique_colors.append({
                'rgb': rgb,
                'hsv': (h, s, v),
                'count': count
            })
            
        # Sort colors by count (descending)
        unique_colors.sort(key=lambda x: x['count'], reverse=True)
        
        # 1. Background / Surface (most dominant dark color)
        dark_colors = [c for c in unique_colors if c['hsv'][2] < 0.35]
        if dark_colors:
            bg_rgb = dark_colors[0]['rgb']
            bg_hsv = dark_colors[0]['hsv']
        else:
            # Fallback to most dominant color made dark
            bg_rgb = unique_colors[0]['rgb']
            h, s, _ = unique_colors[0]['hsv']
            bg_hsv = (h, s, 0.08)
            r, g, b = colorsys.hsv_to_rgb(*bg_hsv)
            bg_rgb = (int(r*255), int(g*255), int(b*255))
            
        # 2. Surface container (slightly lighter dark color)
        sc_hsv = (bg_hsv[0], bg_hsv[1], min(bg_hsv[2] + 0.08, 0.25))
        r, g, b = colorsys.hsv_to_rgb(*sc_hsv)
        sc_rgb = (int(r*255), int(g*255), int(b*255))

        # 3. Vibrant colors (for active border and glow)
        # Filter for colors with decent saturation and value
        vibrant_candidates = [c for c in unique_colors if c['hsv'][1] > 0.15 and c['hsv'][2] > 0.25]
        
        # Sort by vibrancy score: S * V
        vibrant_candidates.sort(key=lambda x: x['hsv'][1] * x['hsv'][2], reverse=True)
        
        if len(vibrant_candidates) >= 1:
            primary_rgb = vibrant_candidates[0]['rgb']
            primary_hsv = vibrant_candidates[0]['hsv']
        else:
            # Fallback: make the most dominant color vibrant
            h, _, _ = unique_colors[0]['hsv']
            primary_hsv = (h, 0.75, 0.85)
            r, g, b = colorsys.hsv_to_rgb(*primary_hsv)
            primary_rgb = (int(r*255), int(g*255), int(b*255))
            
        # Secondary color (second most vibrant, or rotated primary)
        if len(vibrant_candidates) >= 2:
            secondary_rgb = vibrant_candidates[1]['rgb']
        else:
            h, s, v = primary_hsv
            secondary_hsv = ((h + 0.1) % 1.0, s, v)
            r, g, b = colorsys.hsv_to_rgb(*secondary_hsv)
            secondary_rgb = (int(r*255), int(g*255), int(b*255))
            
        # Tertiary color (third most vibrant, or rotated primary)
        if len(vibrant_candidates) >= 3:
            tertiary_rgb = vibrant_candidates[2]['rgb']
        else:
            h, s, v = primary_hsv
            tertiary_hsv = ((h - 0.15) % 1.0, s, v)
            r, g, b = colorsys.hsv_to_rgb(*tertiary_hsv)
            tertiary_rgb = (int(r*255), int(g*255), int(b*255))
            
        # 4. Text / On Surface (very light neutral color)
        on_surface_hsv = (primary_hsv[0], 0.05, 0.95)
        r, g, b = colorsys.hsv_to_rgb(*on_surface_hsv)
        on_surface_rgb = (int(r*255), int(g*255), int(b*255))
        
        # 5. Error Container (soft red)
        error_container_rgb = (255, 174, 164)
        
        # Write to colors.conf (Hyprland format)
        hypr_path = os.path.expanduser("~/.config/hypr/colors.conf")
        with open(hypr_path, "w") as f:
            f.write(f"# Generated colors from {wallpaper}\n\n")
            f.write(f"$background = rgba({rgb_to_hex(bg_rgb)}ff)\n")
            f.write(f"$surface = rgba({rgb_to_hex(bg_rgb)}ff)\n")
            f.write(f"$surface_container = rgba({rgb_to_hex(sc_rgb)}ff)\n")
            f.write(f"$primary = rgba({rgb_to_hex(primary_rgb)}ff)\n")
            f.write(f"$secondary = rgba({rgb_to_hex(secondary_rgb)}ff)\n")
            f.write(f"$tertiary = rgba({rgb_to_hex(tertiary_rgb)}ff)\n")
            f.write(f"$on_surface = rgba({rgb_to_hex(on_surface_rgb)}ff)\n")
            f.write(f"$error_container = rgba({rgb_to_hex(error_container_rgb)}ff)\n")
            
            # Extra variables for Hyprlock glassmorphic glow
            f.write(f"$primary_glow = rgba({rgb_to_hex(primary_rgb)}cc)\n")
            f.write(f"$secondary_glow = rgba({rgb_to_hex(secondary_rgb)}80)\n")
            f.write(f"$secondary_card = rgba({rgb_to_hex(secondary_rgb)}0d)\n")
            
        # Write to .tmux-colors.conf (Tmux format)
        tmux_path = os.path.expanduser("~/.tmux-colors.conf")
        with open(tmux_path, "w") as f:
            f.write(f"# Generated colors from {wallpaper}\n\n")
            f.write(f"set -g status-style bg=Default,fg=#{rgb_to_hex(on_surface_rgb)}\n")
            f.write(f"set -g status-left-length 100\n")
            f.write(f"set -g status-left \"#[fg=#{rgb_to_hex(primary_rgb)},bg=Default]#[fg=#{rgb_to_hex(on_surface_rgb)},bg=#{rgb_to_hex(primary_rgb)},bold] #S#[fg=#{rgb_to_hex(primary_rgb)},bg=Default]\"\n")
            f.write(f"set -g window-status-format \"#[fg=#{rgb_to_hex(sc_rgb)},bg=Default]#[fg=#{rgb_to_hex(on_surface_rgb)},bg=#{rgb_to_hex(sc_rgb)}]#I #W#[fg=#{rgb_to_hex(sc_rgb)},bg=Default]\"\n")
            f.write(f"set -g window-status-current-format \"#[fg=#{rgb_to_hex(secondary_rgb)},bg=Default]#[fg=#{rgb_to_hex(on_surface_rgb)},bg=#{rgb_to_hex(secondary_rgb)},bold]#I #W#[fg=#{rgb_to_hex(secondary_rgb)},bg=Default]\"\n")
            f.write(f"set -g status-right-length 100\n")
            f.write(f"set -g status-right \"#[fg=#{rgb_to_hex(tertiary_rgb)},bg=Default]#[fg=#{rgb_to_hex(on_surface_rgb)},bg=#{rgb_to_hex(tertiary_rgb)},bold]󰃰 %H:%M#[fg=#{rgb_to_hex(tertiary_rgb)},bg=Default]\"\n")
            f.write(f"set -g pane-border-style fg=#{rgb_to_hex(sc_rgb)}\n")
            f.write(f"set -g pane-active-border-style fg=#{rgb_to_hex(primary_rgb)}\n")
            
        # Write to colors.lua (Neovim Lua format)
        nvim_dir = os.path.expanduser("~/.config/nvim/lua")
        os.makedirs(nvim_dir, exist_ok=True)
        nvim_colors_path = os.path.join(nvim_dir, "colors.lua")
        with open(nvim_colors_path, "w") as f:
            f.write(f"-- Generated colors from {wallpaper}\n\n")
            f.write("return {\n")
            f.write(f"  bg = \"#{rgb_to_hex(bg_rgb)}\",\n")
            f.write(f"  surface = \"#{rgb_to_hex(bg_rgb)}\",\n")
            f.write(f"  surface_container = \"#{rgb_to_hex(sc_rgb)}\",\n")
            f.write(f"  primary = \"#{rgb_to_hex(primary_rgb)}\",\n")
            f.write(f"  secondary = \"#{rgb_to_hex(secondary_rgb)}\",\n")
            f.write(f"  tertiary = \"#{rgb_to_hex(tertiary_rgb)}\",\n")
            f.write(f"  on_surface = \"#{rgb_to_hex(on_surface_rgb)}\",\n")
            f.write(f"  error_container = \"#{rgb_to_hex(error_container_rgb)}\",\n")
            f.write("}\n")
            
        # Write to colors.rasi (Rofi CSS format)
        rofi_dir = os.path.expanduser("~/.config/rofi")
        os.makedirs(rofi_dir, exist_ok=True)
        rofi_colors_path = os.path.join(rofi_dir, "colors.rasi")
        with open(rofi_colors_path, "w") as f:
            f.write(f"/* Generated colors from {wallpaper} */\n\n")
            f.write("* {\n")
            f.write(f"    bg-base:             #{rgb_to_hex(bg_rgb)}80;\n")
            f.write(f"    bg-solid:            #{rgb_to_hex(bg_rgb)}ff;\n")
            f.write(f"    bg-alt:              #{rgb_to_hex(sc_rgb)}80;\n")
            f.write(f"    fg-primary:          #{rgb_to_hex(on_surface_rgb)}ff;\n")
            f.write(f"    fg-muted:            #{rgb_to_hex(on_surface_rgb)}99;\n")
            f.write(f"    accent:              #{rgb_to_hex(primary_rgb)}ff;\n")
            f.write(f"    accent-transparent:  #{rgb_to_hex(primary_rgb)}26;\n")
            f.write(f"    urgent:              #{rgb_to_hex(error_container_rgb)}ff;\n")
            f.write("}\n")
            
        # Write to colors.json (Quickshell Material 3 format)
        qs_dir = os.path.expanduser("~/.local/state/quickshell/user/generated")
        os.makedirs(qs_dir, exist_ok=True)
        qs_colors_path = os.path.join(qs_dir, "colors.json")
        
        # Calculate derived Material 3 container & surface shades
        def clamp_rgb(val):
            return max(0, min(255, int(val)))

        def adjust_lightness(rgb, factor):
            return tuple(clamp_rgb(c * factor) for c in rgb)

        sc_high_rgb = adjust_lightness(sc_rgb, 1.25)
        sc_highest_rgb = adjust_lightness(sc_rgb, 1.5)
        primary_container_rgb = adjust_lightness(primary_rgb, 0.45)
        secondary_container_rgb = adjust_lightness(secondary_rgb, 0.45)
        tertiary_container_rgb = adjust_lightness(tertiary_rgb, 0.45)
        
        import json
        qs_palette = {
            "background": f"#{rgb_to_hex(bg_rgb)}",
            "on_background": f"#{rgb_to_hex(on_surface_rgb)}",
            "surface": f"#{rgb_to_hex(bg_rgb)}",
            "surface_dim": f"#{rgb_to_hex(bg_rgb)}",
            "surface_bright": f"#{rgb_to_hex(sc_highest_rgb)}",
            "surface_container_lowest": f"#{rgb_to_hex(adjust_lightness(bg_rgb, 0.7))}",
            "surface_container_low": f"#{rgb_to_hex(bg_rgb)}",
            "surface_container": f"#{rgb_to_hex(sc_rgb)}",
            "surface_container_high": f"#{rgb_to_hex(sc_high_rgb)}",
            "surface_container_highest": f"#{rgb_to_hex(sc_highest_rgb)}",
            "on_surface": f"#{rgb_to_hex(on_surface_rgb)}",
            "surface_variant": f"#{rgb_to_hex(sc_high_rgb)}",
            "on_surface_variant": f"#{rgb_to_hex(on_surface_rgb)}",
            "inverse_surface": f"#{rgb_to_hex(on_surface_rgb)}",
            "inverse_on_surface": f"#{rgb_to_hex(bg_rgb)}",
            "outline": f"#{rgb_to_hex(secondary_rgb)}",
            "outline_variant": f"#{rgb_to_hex(sc_highest_rgb)}",
            "shadow": "#000000",
            "scrim": "#000000",
            "surface_tint": f"#{rgb_to_hex(primary_rgb)}",
            "primary": f"#{rgb_to_hex(primary_rgb)}",
            "on_primary": f"#{rgb_to_hex(bg_rgb)}",
            "primary_container": f"#{rgb_to_hex(primary_container_rgb)}",
            "on_primary_container": f"#{rgb_to_hex(on_surface_rgb)}",
            "secondary": f"#{rgb_to_hex(secondary_rgb)}",
            "on_secondary": f"#{rgb_to_hex(bg_rgb)}",
            "secondary_container": f"#{rgb_to_hex(secondary_container_rgb)}",
            "on_secondary_container": f"#{rgb_to_hex(on_surface_rgb)}",
            "tertiary": f"#{rgb_to_hex(tertiary_rgb)}",
            "on_tertiary": f"#{rgb_to_hex(bg_rgb)}",
            "tertiary_container": f"#{rgb_to_hex(tertiary_container_rgb)}",
            "on_tertiary_container": f"#{rgb_to_hex(on_surface_rgb)}",
            "error": "#ffb4ab",
            "on_error": "#690005",
            "error_container": f"#{rgb_to_hex(error_container_rgb)}",
            "on_error_container": "#ffdad6"
        }

        with open(qs_colors_path, "w") as f:
            json.dump(qs_palette, f, indent=4)
            
        print("Colors extracted and written successfully.")
    except Exception as e:
        print(f"Error processing image: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
