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

  networking.hostName = "nvidia";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  fileSystems."/mnt/HD-A" = {
    device = "/dev/disk/by-uuid/ea3f3a7b-cbea-4e99-ab20-8a089c50a108";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/HD-B" = {
    device = "/dev/disk/by-uuid/debba3c8-86c5-42f0-8ae7-544e675b40c4";
    fsType = "ext4";
    options = [ "nofail" ];
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

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "lucas";
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    capSysAdmin = false;
  };

  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
}
