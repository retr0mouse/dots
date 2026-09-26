#!/usr/bin/env bash

set -euo pipefail

cliphist list | rofi -dmenu -p "clipboard" -i | cliphist decode | wl-copy
