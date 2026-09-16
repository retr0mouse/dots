#!/usr/bin/env bash

GPU="0000:01:00.0"
DRIVER_PATH="/sys/bus/pci/devices/$GPU/driver"

if [[ -L "$DRIVER_PATH" ]]; then
    driver="$(basename "$(readlink -f "$DRIVER_PATH")")"

    case "$driver" in
        vfio-pci)
            echo "TAKEN"
            ;;

        nvidia)
            utilization="$(
                timeout 2 nvidia-smi \
                    --query-gpu=utilization.gpu \
                    --format=csv,noheader,nounits \
                    2>/dev/null
            )"

            if [[ -n "$utilization" ]]; then
                echo "${utilization}%"
            else
                echo "N/A"
            fi
            ;;

        *)
            echo "N/A"
            ;;
    esac
else
    echo "N/A"
fi
