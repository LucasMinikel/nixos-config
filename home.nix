{ config, lib, pkgs, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/hypr/conf.d/keybinds.conf".source = ./home/hypr/conf.d/keybinds.conf;
  home.file.".config/hypr/conf.d/layout.conf".source = ./home/hypr/conf.d/layout.conf;
  home.file.".config/waybar/config".source = ./home/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source = ./home/waybar/style.css;
  home.file.".config/waybar/scripts/gpu-usage.sh" = {
    source = ./home/waybar/scripts/gpu-usage.sh;
    executable = true;
  };
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
    keybinds_line='source = ~/.config/hypr/conf.d/keybinds.conf'
    layout_line='source = ~/.config/hypr/conf.d/layout.conf'
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
      if ! grep -Fxq "$keybinds_line" "$target"; then
        echo "$keybinds_line" >> "$target"
      fi
      if ! grep -Fxq "$layout_line" "$target"; then
        echo "$layout_line" >> "$target"
      fi
    else
      mkdir -p "$HOME/.config/hypr"
      printf '%s\n%s\n' "$keybinds_line" "$layout_line" > "$target"
    fi
  '';

  programs.home-manager.enable = true;
}
