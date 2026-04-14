{ config, lib, pkgs, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/hypr/conf.d/keybinds.conf".source = ./home/hypr/conf.d/keybinds.conf;
  home.file.".config/hypr/conf.d/layout.conf".source = ./home/hypr/conf.d/layout.conf;
  home.file.".config/hypr/conf.d/autostart.conf".source = ./home/hypr/conf.d/autostart.conf;
  home.file.".config/hypr/scripts/wallpaper.sh" = {
    source = ./home/hypr/scripts/wallpaper.sh;
    executable = true;
  };
  home.file.".config/waybar/config".source = ./home/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./home/waybar/style.css;
  home.file.".config/waybar/scripts/gpu-usage.sh" = {
    source = ./home/waybar/scripts/gpu-usage.sh;
    executable = true;
  };
  home.file.".config/wofi/config".source = ./home/wofi/config;
  home.file.".config/wofi/style.css".source = ./home/wofi/style.css;
  home.file.".config/kitty/kitty.conf".source = ./home/kitty/kitty.conf;

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark-BL";
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
    GTK_THEME = "Tokyonight-Dark-BL";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "thunar.desktop" ];
    };
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        "ui.systemUsesDarkTheme" = 1;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  home.activation.ensureHyprKeybindSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/hypr/hyprland.conf"
    keybinds_line="source = $HOME/.config/hypr/conf.d/keybinds.conf"
    layout_line="source = $HOME/.config/hypr/conf.d/layout.conf"
    autostart_line="source = $HOME/.config/hypr/conf.d/autostart.conf"
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
      # corrigir linhas antigas com ~ para $HOME (bug Hyprland 0.54+)
      sed -i "s|source = ~/\.config/hypr/|source = $HOME/.config/hypr/|g" "$target"
      if ! grep -Fxq "$keybinds_line" "$target"; then
        echo "$keybinds_line" >> "$target"
      fi
      if ! grep -Fxq "$layout_line" "$target"; then
        echo "$layout_line" >> "$target"
      fi
      if ! grep -Fxq "$autostart_line" "$target"; then
        echo "$autostart_line" >> "$target"
      fi
    else
      mkdir -p "$HOME/.config/hypr"
      printf '%s\n%s\n' "$keybinds_line" "$layout_line" > "$target"
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
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#nixos";
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
    '';
  };

  programs.home-manager.enable = true;
}
