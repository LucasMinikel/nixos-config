{ lib, ... }:

{
  home.username = "lucas";
  home.homeDirectory = "/home/lucas";
  home.stateVersion = "25.11";

  home.file.".config/hypr/conf.d/keybinds.conf".source = ./home/hypr/conf.d/keybinds.conf;

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
