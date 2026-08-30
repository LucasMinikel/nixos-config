{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };

  programs.gamemode.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "lucas";
  services.displayManager.defaultSession = "steam";

  systemd.tmpfiles.rules = [
    "d /home/lucas/Discos/HD-B/ROMs 0755 lucas users -"
    "d /home/lucas/Discos/HD-B/ROMs/bios 0755 lucas users -"
  ];

  environment.systemPackages = with pkgs; [
    # Windows compat
    wineWow64Packages.stable
    winetricks
    bottles
    lutris
    steamtinkerlaunch
    protonup-ng
    mangohud

    # Retrogaming (RetroArch + emuladores + Steam ROM Manager): fora por
    # enquanto. Vários desses (cores do RetroArch, rpcs3, etc.) não têm
    # binário em cache e precisam compilar do zero clonando repositorios
    # do GitHub, o que trava a instalação se a rede/DNS do instalador não
    # estiver 100%. Primeiro deixa o desktop (Steam+KDE+Wine/Lutris/Bottles)
    # de pé, depois reativa isso com a maquina ja instalada e rede estavel.
  ];
}
