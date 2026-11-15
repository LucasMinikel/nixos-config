{ config, lib, pkgs, ... }:

let
  tokyonight-gtk-theme = pkgs.callPackage ./pkgs/tokyonight-gtk-theme.nix { };
in
{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/hypr/hyprland.lua".source = ./home/hypr/hyprland.lua;
  home.file.".config/hypr/scripts/wallpaper.sh" = {
    source = ./home/hypr/scripts/wallpaper.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/clipboard-menu.sh" = {
    source = ./home/hypr/scripts/clipboard-menu.sh;
    executable = true;
  };
  home.file.".config/hypr/scripts/session-menu.sh" = {
    source = ./home/hypr/scripts/session-menu.sh;
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
  # Papéis de parede vêm do repo via Nix store, sem depender de ~/nixos-config existir
  home.file.".config/hypr/wallpapers".source = ./wallpapers;
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
    "${tokyonight-gtk-theme}/share/themes/Tokyonight-Dark";

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = tokyonight-gtk-theme;
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
    enable = true;
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
    XDG_DATA_DIRS = "${tokyonight-gtk-theme}/share:$XDG_DATA_DIRS";
  };

  # O Hyprland é iniciado direto do tty (sem UWSM), então nada ativa o
  # graphical-session.target. Sem ele o xdg-desktop-portal não sobe e o
  # compartilhamento de tela (Meet etc.) falha.
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland compositor session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  # CLIProxyAPI só escuta em 127.0.0.1 e não inicia sozinho:
  #   systemctl --user start cliproxyapi
  # O config.yaml (com a chave de API) é gerado uma vez em ~/.config, fora do
  # Nix store, que é legível por qualquer usuário.
  systemd.user.services.cliproxyapi = {
    Unit.Description = "CLIProxyAPI (proxy local de modelos)";
    Service = {
      ExecStartPre = "${pkgs.writeShellScript "cliproxyapi-config" ''
        set -eu
        dir="$HOME/.config/cliproxyapi"
        mkdir -p "$dir"
        chmod 700 "$dir"
        if [ ! -f "$dir/config.yaml" ]; then
          key="sk-local-$(${pkgs.coreutils}/bin/head -c 24 /dev/urandom | ${pkgs.coreutils}/bin/base64 | tr -dc 'A-Za-z0-9')"
          umask 077
          cat > "$dir/config.yaml" <<EOF
        server:
          host: "127.0.0.1"
          port: 8317
        management:
          allow-remote: false
        access:
          api-keys:
            - "$key"
        EOF
        fi
      ''}";
      ExecStart = "/run/current-system/sw/bin/cli-proxy-api -config %h/.config/cliproxyapi/config.yaml";
      Restart = "on-failure";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "thunar.desktop" ];
    };
  };

  # Depois de um switch, o Hyprland às vezes recalcula a escala do monitor
  # sozinho (auto-scale) e ignora a regra fixa do hyprland.lua até um reload
  # manual. Isso reaplica a config na sessão que já está rodando.
  home.activation.reloadHyprland = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.hyprland}/bin/hyprctl reload > /dev/null 2>&1 || true
  '';

  # O daemon do Paseo reescreve ~/.paseo/config.json, então ele não pode ser um
  # symlink do Nix store. Mescla só a chave "features" (ditado/voz em pt-BR) e
  # preserva o resto do arquivo.
  home.activation.paseoSpeech = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="$HOME/.paseo/config.json"
    mkdir -p "$HOME/.paseo"
    [ -f "$config" ] || echo '{"version":1}' > "$config"
    tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq --slurpfile features ${./home/paseo/features.json} \
      '.features = ((.features // {}) * $features[0])' "$config" > "$tmp" \
      && install -m 600 "$tmp" "$config"
    rm -f "$tmp"
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
      update = "sudo nixos-rebuild switch --flake ~/projects/nixos-config#$(hostname)";
      sail = "vendor/bin/sail";
    };
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
      fi
    '';
    initContent = ''
      # Uma conta do Claude Code por diretório de config, sem logout/login.
      # A conta "default" continua em ~/.claude. Uso: claude-as <nome> [args]
      claude-as() {
        if [ -z "$1" ]; then
          echo "uso: claude-as <nome-da-conta> [args do claude]" >&2
          return 1
        fi
        local name="$1"; shift
        CLAUDE_CONFIG_DIR="$HOME/.claude-accounts/$name" command claude "$@"
      }

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

  programs.git = {
    enable = true;
    settings.user = {
      name = "LucasMinikel";
      email = "lucasminikel.m@gmail.com";
    };
  };

  # Credential helper usa o gh do PATH, então não quebra quando o store path muda
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.home-manager.enable = true;
}
