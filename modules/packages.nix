{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    kitty
    kdePackages.dolphin
    vscode
    waybar
    wofi
    blueman
    networkmanagerapplet
    pavucontrol
    firefox
  ];
}
