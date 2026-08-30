{ lib, ... }:

{
  home.file.".config/hypr/conf.d/keybinds.conf".source = ./home/hypr/conf.d/keybinds.conf;
  home.file.".config/hypr/conf.d/layout.conf".source = ./home/hypr/conf.d/layout.conf;
  home.file.".config/hypr/conf.d/autostart.conf".source = ./home/hypr/conf.d/autostart.conf;
  home.file.".config/hypr/conf.d/env.conf".source = ./home/hypr/conf.d/env.conf;
  home.file.".config/hypr/scripts/wallpaper.sh" = {
    source = ./home/hypr/scripts/wallpaper.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/screenshot-copy.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="''${1:-area}"
      tmp="$(mktemp --suffix=.png)"

      cleanup() {
          rm -f "$tmp"
      }

      notify() {
          if command -v notify-send >/dev/null 2>&1; then
              notify-send -a screenshot "$@" >/dev/null 2>&1 || true
          fi
      }

      trap cleanup EXIT

      case "$mode" in
          full)
              grim "$tmp"
              ;;
          area)
              geometry="$(slurp)" || exit 0
              [[ -n "$geometry" ]] || exit 0
              grim -g "$geometry" "$tmp"
              ;;
          *)
              echo "Usage: $0 [full|area]" >&2
              exit 2
              ;;
      esac

      wl-copy --type image/png < "$tmp"
      notify "Screenshot copied" "Image copied to clipboard."
    '';
  };
  home.file.".config/waybar/config".source = ./home/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./home/waybar/style.css;
  home.file.".config/waybar/scripts/gpu-usage.sh" = {
    source = ./home/waybar/scripts/gpu-usage.sh;
    executable = true;
  };
  home.file.".config/wofi/config".source = ./home/wofi/config;
  home.file.".config/wofi/style.css".source = ./home/wofi/style.css;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "thunar.desktop" ];
    };
  };

  home.activation.ensureHyprKeybindSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/hypr/hyprland.conf"
    keybinds_line="source = $HOME/.config/hypr/conf.d/keybinds.conf"
    layout_line="source = $HOME/.config/hypr/conf.d/layout.conf"
    autostart_line="source = $HOME/.config/hypr/conf.d/autostart.conf"
    env_line="source = $HOME/.config/hypr/conf.d/env.conf"
    rule1_v1='windowrule = suppressevent maximize, class:.*'
    rule1_v2='windowrulev2 = suppressevent maximize, class:.*'
    rule2_v1='windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0'
    rule2_v1_spaced='windowrule = nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0'
    rule2_v2='windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0'

    if [ -f "$target" ]; then
      sed -i "\\|^$rule1_v1$|d" "$target"
      sed -i "\\|^$rule1_v2$|d" "$target"
      sed -i "\\|^$rule2_v1$|d" "$target"
      sed -i "\\|^$rule2_v1_spaced$|d" "$target"
      sed -i "\\|^$rule2_v2$|d" "$target"
      sed -i "\\|^exec-once = waybar$|d" "$target"
      sed -i '\|^gesture = 3, horizontal, workspace$|d' "$target"
      sed -i '/^\s*pseudotile = true/d' "$target"
      sed -i '/^\s*bind = \$mainMod, J, togglesplit,/d' "$target"
      sed -i '\|^source = \$HOME/.config/hypr/conf.d/keybinds.conf$|d' "$target"
      sed -i '\|^source = \$HOME/.config/hypr/conf.d/layout.conf$|d' "$target"
      sed -i '\|^source = \$HOME/.config/hypr/conf.d/autostart.conf$|d' "$target"
      sed -i '\|^source = \$HOME/.config/hypr/conf.d/env.conf$|d' "$target"
      sed -i '\|^source = ~/.config/hypr/conf.d/keybinds.conf$|d' "$target"
      sed -i '\|^source = ~/.config/hypr/conf.d/layout.conf$|d' "$target"
      sed -i '\|^source = ~/.config/hypr/conf.d/autostart.conf$|d' "$target"
      sed -i '\|^source = ~/.config/hypr/conf.d/env.conf$|d' "$target"
      sed -i "\\|^$keybinds_line$|d" "$target"
      sed -i "\\|^$layout_line$|d" "$target"
      sed -i "\\|^$autostart_line$|d" "$target"
      sed -i "\\|^$env_line$|d" "$target"
      printf '%s\n%s\n%s\n%s\n' \
        "$keybinds_line" \
        "$layout_line" \
        "$autostart_line" \
        "$env_line" >> "$target"
    else
      mkdir -p "$HOME/.config/hypr"
      printf '%s\n%s\n%s\n%s\n' \
        "$keybinds_line" \
        "$layout_line" \
        "$autostart_line" \
        "$env_line" > "$target"
    fi
  '';
}
