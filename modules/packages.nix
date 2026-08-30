{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    unzip
    git
    gnumake
    btop
    kitty
    wl-clipboard
    libnotify
    pavucontrol
    mpv
  ];
}
