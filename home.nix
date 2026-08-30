{ config, lib, pkgs, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

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
  home.file.".config/hypr/hypridle.conf".source = ./home/hypr/hypridle.conf;
  home.file.".config/hypr/hyprlock.conf".source = ./home/hypr/hyprlock.conf;
  home.file.".config/mako/config".source = ./home/mako/config;
  home.file.".config/waybar/config".source = ./home/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./home/waybar/style.css;
  home.file.".config/waybar/scripts/gpu-usage.sh" = {
    source = ./home/waybar/scripts/gpu-usage.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/wifi-menu.sh" = {
    source = ./home/waybar/scripts/wifi-menu.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/bluetooth-menu.sh" = {
    source = ./home/waybar/scripts/bluetooth-menu.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/volume-menu.sh" = {
    source = ./home/waybar/scripts/volume-menu.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/brightness-menu.sh" = {
    source = ./home/waybar/scripts/brightness-menu.sh;
    executable = true;
  };
  home.file.".config/waybar/scripts/power-menu.sh" = {
    source = ./home/waybar/scripts/power-menu.sh;
    executable = true;
  };
  home.file.".config/wofi/config".source = ./home/wofi/config;
  home.file.".config/wofi/style.css".source = ./home/wofi/style.css;
  home.file.".config/kitty/kitty.conf".source = ./home/kitty/kitty.conf;

  # Expor tema GTK em ~/.themes para apps GTK encontrarem
  home.file.".themes/Tokyonight-Dark".source =
    "${pkgs.tokyonight-gtk-theme}/share/themes/Tokyonight-Dark";

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = config.gtk.theme;
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  home.sessionVariables = {
    GTK_THEME = "Tokyonight-Dark";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    XDG_DATA_DIRS = "${pkgs.tokyonight-gtk-theme}/share:$XDG_DATA_DIRS";
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    genericName = "Gerenciador de arquivos";
    exec = "kitty --title yazi -e yazi %U";
    terminal = false;
    categories = [ "System" "FileTools" "FileManager" "ConsoleOnly" ];
    mimeType = [ "inode/directory" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "yazi.desktop" ];
      "application/x-gnome-saved-search" = [ "yazi.desktop" ];
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

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };
    shellAliases = {
      ll   = "ls -la --color=auto";
      la   = "ls -A --color=auto";
      ls   = "ls --color=auto";
      grep = "grep --color=auto";
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      sail = "vendor/bin/sail";
    };
    initContent = ''
      autoload -Uz colors vcs_info
      colors

      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:git:*' formats '%F{141}(%b)%f'
      zstyle ':vcs_info:git:*' actionformats '%F{203}(%b|%a)%f'

      setopt prompt_subst
      precmd() { vcs_info }

      # Tokyo Night prompt: user@host + path atual + branch git
      PROMPT='%F{110}%n@%m%f %F{75}%~%f ''${vcs_info_msg_0_} %# '
      RPROMPT='%F{67}%*%f'

      # Keybindings para navegação de palavras com Ctrl+Seta
      bindkey '^[[1;5C' forward-word     # Ctrl+Right
      bindkey '^[[1;5D' backward-word    # Ctrl+Left
      bindkey '^H' backward-delete-word   # Ctrl+Backspace
      bindkey '^[[3;5~' kill-word        # Ctrl+Delete
    '';
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      sail = "vendor/bin/sail";
    };
  };

  programs.home-manager.enable = true;
}
