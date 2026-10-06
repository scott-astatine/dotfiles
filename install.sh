#!/usr/bin/env bash
set -euo pipefail

readonly MIN_HYPRLAND_LUA_VERSION="0.55.0"
readonly DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

PACKAGES=(
    hyprland quickshell hyprpicker hyprshot hyprsunset hyprpolkitagent
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland
    kitty dolphin rofi fish tmux btop easyeffects blueman network-manager-applet
    pipewire pipewire-pulse wireplumber
    networkmanager bluez bluez-utils
    wl-clipboard cliphist grim slurp wf-recorder libnotify
    jq curl file imagemagick matugen iputils
    brightnessctl ddcutil playerctl pavucontrol
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-hangul fcitx5-configtool qt6ct
    gnome-keyring libsecret
    noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd ttf-roboto
    python python-click python-gobject python-loguru python-tqdm
    python-opencv python-numpy python-pillow gnome-desktop-4
)

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

run_privileged() {
    if (( EUID == 0 )); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        die "sudo is required to install packages and enable system services."
    fi
}

[[ -e /etc/arch-release ]] || die "This installer supports Arch Linux only."
command -v pacman >/dev/null 2>&1 || die "pacman was not found."
(( EUID != 0 )) || die "Run this script as your regular user; it will use sudo for system changes."
[[ -f "$DOTFILES_DIR/quickshell/shell.qml" ]] || die "Run this script from the cloned dotfiles repository."
[[ -f "$DOTFILES_DIR/hypr/hyprland.lua" ]] || die "The Hyprland config was not found in this checkout."

missing_packages=()
for package in "${PACKAGES[@]}"; do
    if ! pacman -Qq "$package" >/dev/null 2>&1; then
        missing_packages+=("$package")
    fi
done

if pacman -Qq hyprland >/dev/null 2>&1; then
    installed_hyprland_version="$(pacman -Q hyprland | awk '{print $2}')"
    if (( $(vercmp "$installed_hyprland_version" "$MIN_HYPRLAND_LUA_VERSION") < 0 )); then
        missing_packages+=(hyprland)
        printf 'Hyprland %s is too old for this Lua config; %s or newer is required.\n' \
            "$installed_hyprland_version" "$MIN_HYPRLAND_LUA_VERSION"
    fi
fi

if ((${#missing_packages[@]})); then
    printf 'Installing missing Arch packages:\n'
    printf '  %s\n' "${missing_packages[@]}"
    run_privileged pacman -S --needed "${missing_packages[@]}"
else
    printf 'All required Pacman packages are already installed.\n'
fi

for package in "${PACKAGES[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || die "Package installation did not provide '$package'."
done

installed_hyprland_version="$(pacman -Q hyprland | awk '{print $2}')"
(( $(vercmp "$installed_hyprland_version" "$MIN_HYPRLAND_LUA_VERSION") >= 0 )) || \
    die "Hyprland $MIN_HYPRLAND_LUA_VERSION or newer is required; installed $installed_hyprland_version."

link_path() {
    local source="$1"
    local destination="$2"
    local backup stamp suffix

    [[ -e "$source" ]] || die "Cannot link missing source: $source"
    mkdir -p -- "$(dirname -- "$destination")"

    if [[ -L "$destination" ]] && [[ "$(readlink -f -- "$destination" 2>/dev/null || true)" == "$(readlink -f -- "$source")" ]]; then
        printf 'Already linked: %s\n' "$destination"
        return
    fi

    if [[ -e "$destination" || -L "$destination" ]]; then
        stamp="$(date +%Y%m%d-%H%M%S)"
        backup="${destination}.backup.${stamp}"
        suffix=1
        while [[ -e "$backup" || -L "$backup" ]]; do
            backup="${destination}.backup.${stamp}.${suffix}"
            ((suffix += 1))
        done
        mv -- "$destination" "$backup"
        printf 'Moved existing config to: %s\n' "$backup"
    fi

    ln -s -- "$source" "$destination"
    printf 'Linked: %s -> %s\n' "$destination" "$source"
}

link_path "$DOTFILES_DIR/quickshell" "$HOME/.config/quickshell"
link_path "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
link_path "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_path "$DOTFILES_DIR/quickshell/src/scripts/wallpaper/setwallpaper.sh" "$HOME/.local/bin/setwall"
link_path "$DOTFILES_DIR/quickshell/src/scripts/wallpaper/shufflewallpaper" "$HOME/.local/bin/shufflewallpaper"

mkdir -p -- "$HOME/.cache"
if [[ ! -e "$HOME/.cache/current_wallpaper.jpg" ]]; then
    magick "$DOTFILES_DIR/quickshell/assets/images/default_wallpaper.png" \
        -quality 90 "$HOME/.cache/current_wallpaper.jpg"
fi

mkdir -p -- "$HOME/.local/share"
python -m venv --system-site-packages "$HOME/.local/share/quickshell-venv"

run_privileged systemctl enable --now NetworkManager.service bluetooth.service
if ! systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
    printf 'Warning: could not start PipeWire user services now; they can be started after login.\n' >&2
fi

printf '\nInstallation complete. Log out and choose the Hyprland session to start the desktop.\n'
printf 'Optional bindings for Spotify, Discord, Antigravity, and Zen Browser assume those apps are installed separately.\n'
