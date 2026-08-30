{ config, pkgs, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/kitty/kitty.conf".source = ./home/kitty/kitty.conf;

  # Expor tema GTK em ~/.themes para apps como Thunar encontrarem
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
