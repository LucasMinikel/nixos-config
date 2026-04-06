{ config, lib, pkgs, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/hypr/conf.d/keybinds.conf".source = ./home/hypr/conf.d/keybinds.conf;
  home.file.".config/waybar/config".source = ./home/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./home/waybar/style.css;
  home.file.".config/wofi/config".source = ./home/wofi/config;
  home.file.".config/wofi/style.css".source = ./home/wofi/style.css;

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = config.gtk.theme;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
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
    source_line='source = ~/.config/hypr/conf.d/keybinds.conf'

    if [ -f "$target" ]; then
      if ! grep -Fxq "$source_line" "$target"; then
        echo "$source_line" >> "$target"
      fi
    else
      mkdir -p "$HOME/.config/hypr"
      printf '%s\n' "$source_line" > "$target"
    fi
  '';

  programs.home-manager.enable = true;
}
