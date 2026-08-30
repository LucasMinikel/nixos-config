{ pkgs, ... }:

let
  # Steam Big Picture chama "steamos-session-select <alvo>" pro botão
  # "Switch to Desktop" — isso só existe no SteamOS/Bazzite, então no NixOS
  # puro o botão fica travado esperando um binário que não existe. Aqui a
  # gente só encerra a sessão gamescope (equivalente a "Exit Steam"), o que
  # devolve pra tela do SDDM em poucos segundos, de onde dá pra entrar no
  # Plasma. Não é a troca instantânea do Bazzite (que depende de uma
  # arquitetura de sessão bem mais complexa), mas para de travar.
  steamos-session-select = pkgs.writeShellScriptBin "steamos-session-select" ''
    case "''${1:-}" in
      plasma|plasma.desktop|desktop)
        ${pkgs.procps}/bin/pkill -x gamescope || true
        ;;
      *)
        exit 0
        ;;
    esac
  '';
in

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
    # O Steam roda dentro do próprio sandbox FHS (bubblewrap) dele — pacotes
    # em environment.systemPackages não aparecem lá dentro. É por isso que o
    # steamos-session-select precisa entrar via extraPackages, não como
    # systemPackage comum.
    extraPackages = [ steamos-session-select ];
  };

  programs.gamemode.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Sem autologin: o botão "Switch to Desktop" do Steam Big Picture depende
  # do steamos-session-select (SteamOS/Bazzite), que não existe aqui — sem
  # autologin, sair da sessão Steam sempre volta pra tela do SDDM, onde dá
  # pra escolher "Steam" ou "Plasma (X11)" manualmente.
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
