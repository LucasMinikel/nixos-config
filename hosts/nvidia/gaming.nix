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

    # Retrogaming: sem frontend, lançado pela Steam via Steam ROM Manager
    (retroarch.withCores (
      cores: with cores; [
        genesis-plus-gx
        snes9x
        beetle-psx
        pcsx_rearmed
        mupen64plus
        mgba
        flycast
        melonds
        ppsspp
      ]
    ))
    pcsx2
    rpcs3
    dolphin-emu
    cemu
    ppsspp
    xemu
    flycast
    mgba
    melonds
    steam-rom-manager
  ];
}
