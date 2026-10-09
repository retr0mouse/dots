set -euo pipefail

connection="qemu:///system"
vm="windows11"
gpu="0000:01:00.0"

open_looking_glass() {
    echo "Starting Looking Glass..."

    if looking-glass-client -f /dev/kvmfr0; then
        lg_status=0
    else
        lg_status=$?
    fi

    echo

    # Check whether Windows was shut down from inside the guest.
    state="$(virsh -c "$connection" domstate "$vm" 2>/dev/null || true)"

    if [[ "$state" == "shut off" ]]; then
        echo "$vm is already shut down."
    elif [[ "$lg_status" -eq 0 ]]; then
        echo "Looking Glass closed."
        echo "Shutting down $vm..."

        virsh -c "$connection" shutdown "$vm"

        echo "Waiting for Windows to shut down..."

        for _ in {1..60}; do
            state="$(virsh -c "$connection" domstate "$vm" 2>/dev/null || true)"

            if [[ "$state" == "shut off" ]]; then
                break
            fi

            sleep 1
        done

        if [[ "$state" != "shut off" ]]; then
            echo
            echo "Windows did not shut down within 60 seconds."
            echo "The VM has NOT been force-stopped."
            exit 1
        fi

        echo "$vm is shut down."
    else
        echo "Looking Glass exited with status $lg_status."
        echo "$vm is still running."
        echo "Leaving the VM untouched."
        exit "$lg_status"
    fi

    # Verify that libvirt returned the RTX to Linux.
    echo "Waiting for RTX 3060 to return to Linux..."

    driver_path="/sys/bus/pci/devices/$gpu/driver"

    for _ in {1..15}; do
        if [[ -L "$driver_path" ]]; then
            driver="$(basename "$(readlink -f "$driver_path")")"

            if [[ "$driver" == "nvidia" ]]; then
                echo "RTX 3060 is back on Linux."
                return 0
            fi
        fi

        sleep 1
    done

    echo
    echo "Windows is shut down, but the RTX did not rebind to NVIDIA."
    echo "Current state:"

    if [[ -L "$driver_path" ]]; then
        driver="$(basename "$(readlink -f "$driver_path")")"
        echo "  driver: $driver"
    else
        echo "  driver: none"
    fi

    return 1
}

state="$(virsh -c "$connection" domstate "$vm" 2>/dev/null || true)"

# If Windows is already running, the RTX already belongs to the VM. Do not
# perform host-side GPU checks; just reconnect with Looking Glass.
if [[ "$state" == "running" ]]; then
    echo "$vm is already running."
    open_looking_glass
    exit $?
fi

# Refuse to steal the RTX from Linux applications.
devices=(
    /dev/nvidia0
    /dev/nvidiactl
    /dev/nvidia-modeset
)

render="/dev/dri/by-path/pci-0000:01:00.0-render"

if [[ -e "$render" ]]; then
    devices+=("$render")
fi

blockers="$(lsof "${devices[@]}" 2>/dev/null || true)"

if [[ -n "$blockers" ]]; then
    echo "RTX 3060 is currently in use:"
    echo
    echo "$blockers"
    echo
    echo "Close applications using the GPU before starting Windows."
    exit 1
fi

# Check that the RTX is in a sane host state.
driver_path="/sys/bus/pci/devices/$gpu/driver"

if [[ -L "$driver_path" ]]; then
    driver="$(basename "$(readlink -f "$driver_path")")"

    if [[ "$driver" != "nvidia" ]]; then
        echo "RTX 3060 is currently bound to: $driver"
        echo "Expected: nvidia"
        echo
        echo "Refusing to start the VM because the GPU may be in a stale state."
        exit 1
    fi
else
    echo "RTX 3060 is currently not bound to any driver."
    echo "Refusing to start the VM because the GPU may be in a stale state."
    exit 1
fi

# Make sure libvirt's NAT network is running.
net_info="$(virsh -c "$connection" net-info default)"

if [[ "$net_info" != *"Active:"*"yes"* ]]; then
    echo "Starting libvirt default network..."
    sudo virsh -c "$connection" net-start default
fi

echo "Starting $vm..."
virsh -c "$connection" start "$vm"

open_looking_glass
