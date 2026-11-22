{ ... }:

{
  # Plex Media Server; a mídia fica em /mnt/HD-B/Media. Roda como lucas para
  # ler os arquivos que já são dele, sem mexer em permissões no HD.
  # A transcodificação pela GPU NVIDIA já é liberada pelo módulo (acesso aos
  # dispositivos e LD_LIBRARY_PATH do driver), mas no Plex ela exige Plex Pass.
  services.plex = {
    enable = true;
    openFirewall = true;
    user = "lucas";
    group = "users";
  };
}
