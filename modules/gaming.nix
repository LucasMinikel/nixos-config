{ pkgs, ... }:

let
  # Ao conectar, o monitor passa para a resolução/FPS do cliente do Moonlight
  # (ex.: 1920x1080 do notebook em vez dos 2560x1080 daqui); ao desconectar,
  # volta para o modo preferido. Mesma regra de monitor do hyprland.lua.
  streamResolution = pkgs.writeShellScript "sunshine-stream-resolution" ''
    if [ "$1" = do ]; then
      mode="''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}"
    else
      mode=preferred
    fi
    ${pkgs.hyprland}/bin/hyprctl eval \
      "hl.monitor({ output = \"\", mode = \"$mode\", position = \"auto\", scale = 1 })"
  '';
in
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
    settings.global_prep_cmd = builtins.toJSON [
      {
        do = "${streamResolution} do";
        undo = "${streamResolution} undo";
      }
    ];
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
