#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WITH_SKETCHYBAR=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--with-sketchybar]

Links the dotfiles appropriate for the current operating system.
Existing files are moved aside with a timestamped .backup suffix.

Options:
  --with-sketchybar  On macOS, install Sketchybar dependencies and its config
  -h, --help         Show this help
EOF
}

while (($#)); do
  case "$1" in
    --with-sketchybar) WITH_SKETCHYBAR=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

backup_path() {
  local path="$1"
  local backup
  local suffix=0

  backup="${path}.backup.$(date +%Y%m%d%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${path}.backup.$(date +%Y%m%d%H%M%S).${suffix}"
  done

  echo "Backing up $path -> $backup"
  mv "$path" "$backup"
}

link_path() {
  local source="$1"
  local destination="$2"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    echo "Missing source: $source" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$destination")"

  if [[ -L "$destination" && "$(readlink "$destination")" == "$source" ]]; then
    echo "Already linked: $destination"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_path "$destination"
  fi

  ln -s "$source" "$destination"
  echo "Linked $destination -> $source"
}

remove_legacy_jj_config() {
  local legacy="$HOME/.jjconfig.toml"
  if [[ -e "$legacy" || -L "$legacy" ]]; then
    backup_path "$legacy"
  fi
}

if command -v git >/dev/null 2>&1; then
  git -C "$DOTFILES_DIR" submodule update --init --recursive
else
  echo "git is required to initialize the Neovim submodule" >&2
  exit 1
fi

# Cross-platform configuration.
link_path "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_DIR/neovim_config" "$HOME/.config/nvim"
link_path "$DOTFILES_DIR/tmux_conf/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link_path "$DOTFILES_DIR/tmux_conf/tpm" "$HOME/.config/tmux/tpm"
link_path "$DOTFILES_DIR/jj/config.toml" "$HOME/.config/jj/config.toml"
link_path "$DOTFILES_DIR/zls/zls.json" "$HOME/.config/zls.json"
link_path "$DOTFILES_DIR/.pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"
remove_legacy_jj_config

case "$(uname -s)" in
  Linux)
    link_path "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
    link_path "$DOTFILES_DIR/mako" "$HOME/.config/mako"
    link_path "$DOTFILES_DIR/niri" "$HOME/.config/niri"
    link_path "$DOTFILES_DIR/wofi" "$HOME/.config/wofi"
    link_path "$DOTFILES_DIR/wpaperd" "$HOME/.config/wpaperd"
    ;;
  Darwin)
    ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
    link_path "$DOTFILES_DIR/ghostty/config" "$ghostty_dir/config"
    link_path "$DOTFILES_DIR/ghostty/shaders" "$ghostty_dir/shaders"
    link_path "$DOTFILES_DIR/aerospace" "$HOME/.config/aerospace"

    if [[ "$WITH_SKETCHYBAR" == true ]]; then
      "$DOTFILES_DIR/sketchybar/install_sketchybar.sh"
    else
      echo "Skipping Sketchybar; pass --with-sketchybar to install it."
    fi
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)" >&2
    exit 1
    ;;
esac

echo
echo "Dotfiles installed successfully."
if [[ "$(uname -s)" == Linux ]]; then
  echo "NixOS can be rebuilt with: sudo nixos-rebuild switch --flake '$DOTFILES_DIR/nix#nixos'"
fi
