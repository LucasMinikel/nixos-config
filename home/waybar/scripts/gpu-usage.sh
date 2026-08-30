#!/usr/bin/env bash

# Try NVIDIA, then Intel (intel_gpu_top), then AMD sysfs. Print nothing when no real metric exists.
if command -v intel_gpu_top >/dev/null 2>&1; then
  usage="$(
    intel_gpu_top -J -s 200 -n 2 -o - 2>/dev/null | node -e '
      let raw = "";
      process.stdin.on("data", (c) => (raw += c));
      process.stdin.on("end", () => {
        const objects = raw
          .split(/(?<=\})\s*(?=\{)/)
          .map((s) => {
            try {
              return JSON.parse(s);
            } catch {
              return null;
            }
          })
          .filter(Boolean);
        const last = objects[objects.length - 1];
        const engines = last && last.engines;
        if (!engines) process.exit(1);
        const render = engines["Render/3D"] || engines["Render/3D/0"];
        const busy = render && parseFloat(render.busy);
        if (!Number.isFinite(busy)) process.exit(1);
        process.stdout.write(String(Math.round(busy)));
      });
    '
  )"
  if [[ "$usage" =~ ^[0-9]+$ ]]; then
    printf "󰒋 %s%%\n" "$usage"
    exit 0
  fi
fi

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
