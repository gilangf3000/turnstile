#!/usr/bin/env bash

set -euo pipefail

YARN_SOURCE=""
YARN_SOURCE_DISABLED=""

restore_yarn_repo() {
  if [ -n "$YARN_SOURCE_DISABLED" ] && [ -f "$YARN_SOURCE_DISABLED" ]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo mv "$YARN_SOURCE_DISABLED" "$YARN_SOURCE"
    elif [ "$(id -u)" -eq 0 ]; then
      mv "$YARN_SOURCE_DISABLED" "$YARN_SOURCE"
    fi
  fi
}

pkg_exists() {
  local candidate
  candidate="$(apt-cache policy "$1" 2>/dev/null | awk -F': ' '/Candidate:/ {print $2; exit}')"
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ]
}

pick_pkg() {
  for name in "$@"; do
    if pkg_exists "$name"; then
      echo "$name"
      return 0
    fi
  done

  return 1
}

add_pkg() {
  local resolved
  resolved="$(pick_pkg "$@")" || return 0
  APT_PACKAGES+=("$resolved")
}

trap restore_yarn_repo EXIT

echo "installing npm packages..."
npm install

if command -v apt-get >/dev/null 2>&1; then
  APT_PACKAGES=()

  if [ -f /etc/apt/sources.list.d/yarn.list ]; then
    YARN_SOURCE="/etc/apt/sources.list.d/yarn.list"
    YARN_SOURCE_DISABLED="/etc/apt/sources.list.d/yarn.list.disabled"
  elif [ -f /etc/apt/sources.list.d/yarn.sources ]; then
    YARN_SOURCE="/etc/apt/sources.list.d/yarn.sources"
    YARN_SOURCE_DISABLED="/etc/apt/sources.list.d/yarn.sources.disabled"
  fi

  if [ -n "$YARN_SOURCE" ]; then
    echo "temporarily disabling broken yarn repo..."
    if command -v sudo >/dev/null 2>&1; then
      sudo mv "$YARN_SOURCE" "$YARN_SOURCE_DISABLED"
    elif [ "$(id -u)" -eq 0 ]; then
      mv "$YARN_SOURCE" "$YARN_SOURCE_DISABLED"
    fi
  fi

  echo "installing linux packages for chromium..."
  add_pkg libasound2 libasound2t64
  add_pkg libatk-bridge2.0-0
  add_pkg libatk1.0-0 libatk1.0-0t64
  add_pkg libcups2 libcups2t64
  add_pkg libdbus-1-3
  add_pkg libdrm2
  add_pkg libgbm1
  add_pkg libglib2.0-0 libglib2.0-0t64
  add_pkg libgtk-3-0 libgtk-3-0t64
  add_pkg libnspr4
  add_pkg libnss3
  add_pkg libpango-1.0-0 libpango-1.0-0t64
  add_pkg libx11-6
  add_pkg libx11-xcb1
  add_pkg libxcb1
  add_pkg libxcomposite1
  add_pkg libxdamage1
  add_pkg libxext6
  add_pkg libxfixes3
  add_pkg libxkbcommon0
  add_pkg libxrandr2

  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
  elif [ "$(id -u)" -eq 0 ]; then
    apt-get update
    apt-get install -y "${APT_PACKAGES[@]}"
  fi
fi

if command -v sudo >/dev/null 2>&1; then
  echo "installing playwright chromium with system deps..."
  sudo npx playwright install --with-deps chromium
elif [ "$(id -u)" -eq 0 ]; then
  echo "installing playwright chromium with system deps..."
  npx playwright install --with-deps chromium
else
  echo "installing playwright chromium..."
  npx playwright install chromium
  echo "warning: system deps were not installed automatically"
  echo "if chromium fails to start, run one of these:"
  echo "  sudo npx playwright install --with-deps chromium"
  echo "  npx playwright install-deps chromium"
  echo "  sudo apt-get install -y libatk1.0-0 libatk1.0-0t64 libgtk-3-0 libgtk-3-0t64 libnss3 libx11-xcb1"
fi

echo "setup done"
