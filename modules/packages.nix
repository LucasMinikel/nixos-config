{ pkgs, ... }:

{
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
    vscode
    google-chrome
  ];
}
