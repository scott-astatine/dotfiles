set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
set -gx CC clang
set -gx CXX clang++
set -gx CPP 'clang -E'

fish_add_path --append \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$PNPM_HOME" \
    "$HOME/.pub-cache/bin"

if status is-interactive && type -q fastfetch
    fastfetch
end
