{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/packages.nix
    ./modules/nvidia.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = false;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.insertNameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

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

  services.xserver.xkb.layout = "us";

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  fileSystems."/home/lucas/Discos/HD-A" = {
    device = "/dev/disk/by-uuid/ea3f3a7b-cbea-4e99-ab20-8a089c50a108";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.idle-timeout=600" "x-gvfs-show" ];
  };

  fileSystems."/home/lucas/Discos/HD-B" = {
    device = "/dev/disk/by-uuid/debba3c8-86c5-42f0-8ae7-544e675b40c4";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.idle-timeout=600" "x-gvfs-show" ];
  };

  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas Minikel";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  programs.zsh.enable = true;

  users.users.lucas.shell = pkgs.zsh;

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  system.stateVersion = "25.11";
}
