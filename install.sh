#!/usr/bin/env bash
set -euo pipefail

readonly MIN_HYPRLAND_LUA_VERSION="0.55.0"
readonly GOOGLE_SANS_FLEX_VERSION="v4.007"
readonly GOOGLE_SANS_FLEX_SHA256="b7375131bffc5eaaebeb65c69529ba10e7f7a9962b913488f6ef35c432ce19c9"
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
    noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd ttf-roboto ttf-material-symbols-variable fontconfig libarchive
    python python-click python-gobject python-loguru python-tqdm
    python-opencv python-numpy python-pillow gnome-desktop-4
)

AUR_FONT_PACKAGES=(otf-space-grotesk ttf-readex-pro)

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

missing_aur_font_packages=()
for package in "${AUR_FONT_PACKAGES[@]}"; do
    if ! pacman -Qq "$package" >/dev/null 2>&1; then
        missing_aur_font_packages+=("$package")
    fi
done

if ((${#missing_aur_font_packages[@]})) && ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
    die "Install yay or paru to install the AUR fonts: ${missing_aur_font_packages[*]}"
fi

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

if ((${#missing_aur_font_packages[@]})); then
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed "${missing_aur_font_packages[@]}"
    elif command -v paru >/dev/null 2>&1; then
        paru -S --needed "${missing_aur_font_packages[@]}"
    fi
fi

for package in "${AUR_FONT_PACKAGES[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || die "AUR font installation did not provide '$package'."
done

installed_hyprland_version="$(pacman -Q hyprland | awk '{print $2}')"
(( $(vercmp "$installed_hyprland_version" "$MIN_HYPRLAND_LUA_VERSION") >= 0 )) || \
    die "Hyprland $MIN_HYPRLAND_LUA_VERSION or newer is required; installed $installed_hyprland_version."

install_google_sans_flex() (
    if [[ "$(fc-match -f '%{family}' 'Google Sans Flex')" == *"Google Sans Flex"* ]]; then
        printf 'Google Sans Flex is already installed.\n'
        return
    fi

    local temp_dir archive_path font_path font_name download_url
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$temp_dir"' EXIT
    font_name='GoogleSansFlex[GRAD,ROND,opsz,slnt,wdth,wght].ttf'
    archive_path="$temp_dir/GoogleSansFlex-${GOOGLE_SANS_FLEX_VERSION}.zip"
    font_path="$HOME/.local/share/fonts/$font_name"
    download_url="https://github.com/googlefonts/googlesans-flex/releases/download/${GOOGLE_SANS_FLEX_VERSION}/GoogleSansFlex-${GOOGLE_SANS_FLEX_VERSION}.zip"

    curl --fail --location --silent --show-error "$download_url" --output "$archive_path"
    printf '%s  %s\n' "$GOOGLE_SANS_FLEX_SHA256" "$archive_path" | sha256sum --check --status || \
        die "Google Sans Flex archive checksum verification failed."

    mkdir -p -- "$(dirname -- "$font_path")"
    bsdtar -xOf "$archive_path" 'GoogleSansFlex*.ttf' > "$temp_dir/$font_name" || \
        die "Google Sans Flex archive did not contain the expected font file."
    fc-scan --format '%{family}\n' "$temp_dir/$font_name" | grep -Fq 'Google Sans Flex' || \
        die "Downloaded file is not a valid Google Sans Flex font."
    install -m 644 -- "$temp_dir/$font_name" "$font_path"
    fc-cache --force "$HOME/.local/share/fonts"
    printf 'Installed Google Sans Flex to %s\n' "$font_path"
)

install_google_sans_flex

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
link_path "$DOTFILES_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
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
