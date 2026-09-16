#!/usr/bin/env bash

CARD=$(ls /sys/class/drm/ | grep -E '^card[0-9]+$' | while read -r card; do
    if [[ -f "/sys/class/drm/$card/device/gpu_busy_percent" ]]; then
        echo "$card"
        break
    fi
done)

if [[ -n "$CARD" && -f "/sys/class/drm/$CARD/device/gpu_busy_percent" ]]; then
    awk '{print $1 "%"}' "/sys/class/drm/$CARD/device/gpu_busy_percent"
else
    echo "N/A"
fi
