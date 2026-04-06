{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    btop
    kitty
    kdePackages.dolphin
    vscode
    waybar
    wofi
    blueman
    networkmanagerapplet
    pavucontrol
    firefox
    nerd-fonts.jetbrains-mono
  ];
}
