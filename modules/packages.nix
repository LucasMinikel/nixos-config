{ config, lib, pkgs, ... }:

let
  cfg = config.lucas.desktopApps;
in

{
  options.lucas.desktopApps = {
    heavy.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install heavier desktop apps such as VS Code and Chrome.";
    };
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      gnumake
      btop
      kitty
      thunar
      awww
      waybar
      wofi
      blueman
      networkmanagerapplet
      pavucontrol
      mpv
      libreoffice
      qbittorrent
      gh
      docker-compose
      nerd-fonts.jetbrains-mono
    ] ++ lib.optionals cfg.heavy.enable (with pkgs; [
      vscode
      google-chrome
    ]);
  };
}
