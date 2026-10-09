#!/usr/bin/env bash

if ! command -v bluetoothctl >/dev/null; then
    echo ""
    exit 0
fi

adapter_powered=$(timeout 2 bluetoothctl show 2>/dev/null |
    awk -F': ' '/Powered:/ {print $2}')

if [ "$adapter_powered" != "yes" ]; then
    jq -cn '{
        text: "󰂲",
        class: "disabled",
        tooltip: "Bluetooth disabled"
    }'
    exit 0
fi

connected_devices=$(timeout 2 bluetoothctl devices Connected 2>/dev/null |
    sed 's/^Device [^ ]* //')

count=$(printf '%s\n' "$connected_devices" | grep -c .)

if [ "$count" -gt 0 ]; then
    text="󰂯 $count"
    tooltip="Connected devices:
$connected_devices"
else
    text="󰂯"
    tooltip="No connected devices"
fi

jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    '{
        text: $text,
        tooltip: $tooltip
    }'
