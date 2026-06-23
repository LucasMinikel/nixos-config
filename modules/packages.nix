{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    btop
    kitty
    thunar
    awww
    vscode
    waybar
    wofi
    blueman
    networkmanagerapplet
    pavucontrol
    libreoffice
    google-chrome
    qbittorrent
    gh
    docker-compose
    nerd-fonts.jetbrains-mono
  ];
}
