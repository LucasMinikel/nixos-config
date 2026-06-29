{ pkgs, ... }:

{
  imports = [
    ./modules/packages.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.insertNameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.hosts = {
    "127.0.0.1" = [ "laravel.test" ];
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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  hardware.enableRedistributableFirmware = true;

  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas Minikel";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [];
  };

  programs.zsh.enable = true;

  users.users.lucas.shell = pkgs.zsh;

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  hardware.graphics.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  virtualisation.docker.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  system.stateVersion = "25.11";
}
