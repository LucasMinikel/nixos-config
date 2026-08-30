{ lib, ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "generic";

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Login automático no tty1; o Hyprland é iniciado pelo .zprofile e já
  # abre travado (hyprlock), então a senha real continua sendo exigida ali.
  services.getty.autologinUser = "lucas";
}
