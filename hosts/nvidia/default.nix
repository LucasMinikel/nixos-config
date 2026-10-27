{ ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
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

  fileSystems."/mnt/HD-A" = {
    device = "/dev/disk/by-uuid/8418348318347670";
    fsType = "ntfs3";
    options = [ "nofail" "uid=1000" "gid=100" "umask=022" ];
  };

  fileSystems."/mnt/HD-B" = {
    device = "/dev/disk/by-uuid/885038E95038E01C";
    fsType = "ntfs3";
    options = [ "nofail" "uid=1000" "gid=100" "umask=022" ];
  };

  fileSystems."/home/lucas/Discos/HD-A" = {
    device = "/mnt/HD-A";
    fsType = "none";
    options = [ "bind" "nofail" "x-gvfs-show" ];
    depends = [ "/mnt/HD-A" ];
  };

  fileSystems."/home/lucas/Discos/HD-B" = {
    device = "/mnt/HD-B";
    fsType = "none";
    options = [ "bind" "nofail" "x-gvfs-show" ];
    depends = [ "/mnt/HD-B" ];
  };
}
