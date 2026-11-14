#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "Sketchybar installation is only supported on macOS." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

install_formula() {
  local package="$1"
  if brew list --formula "$package" >/dev/null 2>&1; then
    echo "Formula already installed: $package"
  else
    brew install "$package"
  fi
}

install_cask() {
  local package="$1"
  if brew list --cask "$package" >/dev/null 2>&1; then
    echo "Cask already installed: $package"
  else
    brew install --cask "$package"
  fi
}

backup_path() {
  local path="$1"
  local backup="${path}.backup.$(date +%Y%m%d%H%M%S)"
  local suffix=0

  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${path}.backup.$(date +%Y%m%d%H%M%S).${suffix}"
  done

  echo "Backing up $path -> $backup"
  mv "$path" "$backup"
}

install_formula sketchybar
install_cask sf-symbols
install_cask font-sf-mono
install_cask font-sf-pro

font_dir="$HOME/Library/Fonts"
app_font="$font_dir/sketchybar-app-font.ttf"
mkdir -p "$font_dir"
if [[ ! -f "$app_font" ]]; then
  curl --fail --location \
    https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf \
    --output "$app_font"
else
  echo "Font already installed: $app_font"
fi

config_dir="$HOME/.config/sketchybar"
repo_https="https://github.com/f3lixding/sketchybar_conf.git"
repo_ssh="git@github.com:f3lixding/sketchybar_conf.git"
mkdir -p "$HOME/.config"

if [[ -d "$config_dir/.git" ]]; then
  current_remote="$(git -C "$config_dir" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_remote" == "$repo_https" || "$current_remote" == "$repo_ssh" ]]; then
    git -C "$config_dir" pull --ff-only
  else
    backup_path "$config_dir"
    git clone "$repo_https" "$config_dir"
  fi
elif [[ -e "$config_dir" || -L "$config_dir" ]]; then
  backup_path "$config_dir"
  git clone "$repo_https" "$config_dir"
else
  git clone "$repo_https" "$config_dir"
fi

brew services restart sketchybar
