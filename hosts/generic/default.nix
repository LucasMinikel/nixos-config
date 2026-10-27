{ lib, ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "generic";

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # O mDNS (nvidia.local) não resolve aqui; IP fixo do nvidia na LAN.
  networking.hosts."192.168.15.25" = [ "nvidia" ];
  programs.ssh.knownHosts.nvidia = {
    hostNames = [ "nvidia" "nvidia.local" "192.168.15.25" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL52bvC8Fo8i09yefNwFSQM99OIFT23zlHkl+Aghu1Hx";
  };
}
