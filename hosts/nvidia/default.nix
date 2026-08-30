{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/packages.nix
    ../../modules/nvidia.nix
    ../../modules/claude-code.nix
    ./gaming.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = false;

  networking.hostName = "nvidia";
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "br";
    variant = "nodeadkeys";
  };
  console.useXkbConfig = true;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true; # pareamento de controles

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas Minikel";
    extraGroups = [ "networkmanager" "wheel" "uinput" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUcfWC5iYENU+lQIAtxojJZdpf1VD1eL8IQk0ZWs8zb lucas@generic"
    ];
  };
  programs.zsh.enable = true;

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

  system.stateVersion = "25.11";
}
