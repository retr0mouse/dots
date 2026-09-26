#!/usr/bin/env bash

set -euo pipefail

screenshot_file="$(mktemp --suffix=.png)"
freeze_pid=""

cleanup() {
    if [[ -n "$freeze_pid" ]]; then
        kill "$freeze_pid" 2>/dev/null || true
        wait "$freeze_pid" 2>/dev/null || true
    fi

    rm -f -- "$screenshot_file"
}

trap cleanup EXIT INT TERM

# Hyprpicker renders the current desktop into a frozen fullscreen layer. Slurp
# runs above it, so selection is made against the frame that will be captured.
hyprpicker -r -z >/dev/null 2>&1 &
freeze_pid=$!
sleep 0.2

if ! geometry="$(
    slurp \
        -d \
        -b '#101211cc' \
        -c '#98a87cff' \
        -s '#1a1d1b66' \
        -B '#303630ff' \
        -F 'Iosevka Nerd Font' \
        -w 1
)"; then
    exit 0
fi

grim -g "$geometry" "$screenshot_file"

# Unfreeze before opening the annotation window.
kill "$freeze_pid" 2>/dev/null || true
wait "$freeze_pid" 2>/dev/null || true
freeze_pid=""

swappy -f "$screenshot_file"
