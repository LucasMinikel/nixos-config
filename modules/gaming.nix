{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # DualShock 4 e DualSense não precisam de driver extra: o kernel tem
  # hid-sony/hid-playstation, e as regras de udev da Steam e do Sunshine
  # liberam hidraw/uhid (giroscópio, touchpad e a emulação no Moonlight).

  # Streaming dos jogos para TV, celular e o generic via Moonlight.
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    capSysAdmin = false;
  };

  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";

  environment.systemPackages = with pkgs; [
    # Jogos fora da Steam: GOG/Epic/Amazon e instaladores avulsos de Windows.
    heroic
    lutris
    bottles
    mangohud
  ];
}
