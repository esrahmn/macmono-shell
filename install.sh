#!/usr/bin/env bash
# macmono installer
# https://github.com/esrahmn/macmono-shell
#
# Usage:
#   ./install.sh [options]
#   bash <(curl -fsSL https://raw.githubusercontent.com/esrahmn/macmono-shell/main/install.sh)
#
# Options:
#   -l, --link       Symlink configs instead of copying (edits in the repo apply live)
#   -n, --no-deps    Skip installing packages
#   -y, --yes        Do not ask for confirmation (non-interactive)
#   -h, --help       Show this help

set -euo pipefail

REPO_URL="https://github.com/esrahmn/macmono-shell.git"
CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/macmono-shell"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_SOURCES=(hypr macmono)
CONFIG_TARGETS=(hypr quickshell/macmono)
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

MODE="copy"
INSTALL_DEPS=1
ASSUME_YES=0

PACKAGES=(
  # core
  hyprland hyprlock hypridle quickshell
  # services
  pipewire networkmanager bluez bluez-utils upower
  # utilities
  brightnessctl libnotify jq cava playerctl bc
  # screenshot, clipboard, recording
  grim slurp imagemagick wl-clipboard cliphist wf-recorder
)
POLKIT_AGENTS=(polkit-kde-agent hyprpolkitagent polkit-gnome)

if [[ -t 1 ]]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RESET=$'\e[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

info() { printf '%s==>%s %s\n' "$GREEN$BOLD" "$RESET" "$*"; }
warn() { printf '%s==> warning:%s %s\n' "$YELLOW$BOLD" "$RESET" "$*" >&2; }
fail() { printf '%s==> error:%s %s\n' "$RED$BOLD" "$RESET" "$*" >&2; exit 1; }

usage() {
  sed -n '2,14p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'
}

confirm() {
  local prompt="$1"
  (( ASSUME_YES )) && return 0
  local reply
  read -r -p "$prompt [Y/n] " reply </dev/tty || return 1
  [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

parse_args() {
  while (( $# )); do
    case "$1" in
      -l|--link)    MODE="link" ;;
      -n|--no-deps) INSTALL_DEPS=0 ;;
      -y|--yes)     ASSUME_YES=1 ;;
      -h|--help)    usage; exit 0 ;;
      *)            fail "Unknown option: $1 (try --help)" ;;
    esac
    shift
  done
}

preflight() {
  (( EUID != 0 )) || fail "Do not run this as root. It installs into your home directory and calls sudo when needed."
  [[ -n "${HOME:-}" ]] || fail "\$HOME is not set."
  command -v git >/dev/null 2>&1 || fail "git is required."
}

repo_has_configs() {
  [[ -d "$1/macmono/config/hypr" && -d "$1/macmono/config/macmono" ]]
}

# Find the repo: next to this script, or clone it when run through curl.
locate_repo() {
  local script_path="${BASH_SOURCE[0]:-}"
  local script_dir=""
  if [[ -n "$script_path" && -f "$script_path" ]]; then
    script_dir="$(cd "$(dirname "$script_path")" && pwd)"
  fi

  if [[ -n "$script_dir" ]] && repo_has_configs "$script_dir"; then
    REPO_DIR="$script_dir"
    return
  fi

  info "Repository not found next to the script, cloning into $CLONE_DIR"
  if [[ -d "$CLONE_DIR/.git" ]]; then
    git -C "$CLONE_DIR" pull --ff-only
  else
    mkdir -p "$(dirname "$CLONE_DIR")"
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
  fi
  REPO_DIR="$CLONE_DIR"

  repo_has_configs "$REPO_DIR" || fail "Repository is missing macmono/config/hypr or macmono/config/macmono."
}

install_packages() {
  if ! command -v pacman >/dev/null 2>&1; then
    warn "pacman not found, skipping package install. Install the dependencies from the README manually."
    return
  fi

  local packages=("${PACKAGES[@]}")
  local has_polkit=0 agent
  for agent in "${POLKIT_AGENTS[@]}"; do
    if pacman -Qq "$agent" >/dev/null 2>&1; then has_polkit=1; break; fi
  done
  (( has_polkit )) || packages+=(hyprpolkitagent)

  local missing=() pkg
  for pkg in "${packages[@]}"; do
    pacman -Qq "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if (( ${#missing[@]} == 0 )); then
    info "All dependencies are already installed."
    return
  fi

  info "Missing packages: ${missing[*]}"
  if ! confirm "Install them with pacman?"; then
    warn "Skipping package install."
    return
  fi

  local flags=(-S --needed)
  (( ASSUME_YES )) && flags+=(--noconfirm)
  sudo pacman "${flags[@]}" "${missing[@]}"
}

enable_services() {
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl is-enabled bluetooth.service >/dev/null 2>&1 && return 0
  systemctl list-unit-files bluetooth.service >/dev/null 2>&1 || return 0

  if confirm "Enable the Bluetooth service (needed for the Control Center)?"; then
    sudo systemctl enable --now bluetooth.service
  fi
}

backup_existing() {
  local relative target
  for relative in "${CONFIG_TARGETS[@]}"; do
    target="$CONFIG_DIR/$relative"
    if [[ -e "$target" || -L "$target" ]]; then
      mv "$target" "$target.bak-$TIMESTAMP"
      info "Backed up $target to $target.bak-$TIMESTAMP"
    fi
  done
}

install_configs() {
  local src_root="$REPO_DIR/macmono/config"
  mkdir -p "$CONFIG_DIR"

  local source relative
  for source in "${CONFIG_SOURCES[@]}"; do
    [[ -d "$src_root/$source" ]] || fail "Missing $src_root/$source in the repository."
  done

  backup_existing

  local index
  for index in "${!CONFIG_SOURCES[@]}"; do
    source="${CONFIG_SOURCES[$index]}"
    relative="${CONFIG_TARGETS[$index]}"
    mkdir -p "$(dirname "$CONFIG_DIR/$relative")"
    if [[ "$MODE" == "link" ]]; then
      ln -s "$src_root/$source" "$CONFIG_DIR/$relative"
      info "Linked $CONFIG_DIR/$relative -> $src_root/$source"
    else
      cp -r "$src_root/$source" "$CONFIG_DIR/$relative"
      info "Copied $source to $CONFIG_DIR/$relative"
    fi
  done

  if [[ "$MODE" == "copy" ]]; then
    find "$CONFIG_DIR/quickshell/macmono" "$CONFIG_DIR/hypr/hyprland/scripts" \
      -type f -name '*.sh' -exec chmod +x {} +
  fi
}

finish() {
  printf '\n%smacmono is installed.%s\n' "$GREEN$BOLD" "$RESET"
  printf '%s\n' \
    "  * Log out and log back into Hyprland, or" \
    "  * start the shell right now with: ${BOLD}qs -c macmono${RESET}" \
    "" \
    "${DIM}Previous configs (if any) were saved as *.bak-$TIMESTAMP in $CONFIG_DIR.${RESET}"
}

main() {
  parse_args "$@"
  preflight
  locate_repo

  info "macmono installer (mode: $MODE)"
  (( INSTALL_DEPS )) && install_packages && enable_services

  if ! confirm "Install configs into $CONFIG_DIR? Existing hypr/ and quickshell/macmono/ will be backed up."; then
    fail "Aborted."
  fi
  install_configs
  finish
}

main "$@"
