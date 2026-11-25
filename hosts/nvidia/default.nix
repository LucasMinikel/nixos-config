{ ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
    ../../modules/media.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.configurationLimit = 10;

  networking.hostName = "nvidia";

  # O T3 Code do generic usa este host como ambiente SSH.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "lucas" ];
    };
  };

  # O T3 Code do generic baixa aqui um t3 pré-compilado (glibc genérico)
  # para o ambiente SSH; sem nix-ld ele não executa no NixOS.
  programs.nix-ld.enable = true;

  # x-gvfs-show põe cada disco uma vez na lateral do Thunar.
  fileSystems."/mnt/HD-A" = {
    device = "/dev/disk/by-label/HD-A";
    fsType = "ext4";
    options = [ "nofail" "x-gvfs-show" ];
  };

  fileSystems."/mnt/HD-B" = {
    device = "/dev/disk/by-label/HD-B";
    fsType = "ext4";
    options = [ "nofail" "x-gvfs-show" ];
  };
}
