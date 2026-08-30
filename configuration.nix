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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  hardware.enableRedistributableFirmware = true;

  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas Minikel";
    extraGroups = [ "networkmanager" "wheel" "docker" "uinput" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUcfWC5iYENU+lQIAtxojJZdpf1VD1eL8IQk0ZWs8zb lucas@generic"
    ];
  };

  programs.zsh.enable = true;

  users.users.lucas.shell = pkgs.zsh;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  virtualisation.docker.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Permite ler contadores de uso da GPU Intel (intel_gpu_top) sem rodar como root,
  # concedendo CAP_PERFMON só a esse binário em vez de afrouxar perf_event_paranoid globalmente.
  security.wrappers.intel_gpu_top = {
    source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
    capabilities = "cap_perfmon=+ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+x,o+x";
  };

  system.stateVersion = "25.11";
}
