#!/usr/bin/env bash

# Try NVIDIA first, then AMD sysfs. Print nothing when no real metric exists.
if command -v nvidia-smi >/dev/null 2>&1; then
  usage="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')"
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "󰒋 %s%%\n" "$usage"
    exit 0
  fi
fi

for gpu_busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
  [[ -r "$gpu_busy_file" ]] || continue

  usage="$(cat "$gpu_busy_file" 2>/dev/null | tr -d '[:space:]')"
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "󰒋 %s%%\n" "$usage"
    exit 0
  fi
done

exit 1
