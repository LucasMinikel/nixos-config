{ ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.configurationLimit = 10;

  networking.hostName = "nvidia";

  # O Paseo do generic usa este host via SSH (ssh -W até o daemon em
  # 127.0.0.1:6767), então o daemon em si continua fechado para a rede.
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
