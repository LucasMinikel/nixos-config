#!/usr/bin/env bash

# Try NVIDIA first, then AMD sysfs. Print a single compact label for Waybar.
if command -v nvidia-smi >/dev/null 2>&1; then
  usage="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')"
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "󰒋 %s%%\n" "$usage"
    exit 0
  fi
fi

if [[ -r /sys/class/drm/card0/device/gpu_busy_percent ]]; then
  usage="$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null | tr -d '[:space:]')"
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "󰒋 %s%%\n" "$usage"
    exit 0
  fi
fi

printf "󰒋 N/A\n"
