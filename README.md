# NixOS Config - Guia Rapido de Comandos

Este repositório usa flakes e Home Manager para manter o sistema declarativo.

## 1) Hosts disponiveis

Este repositório tem uma base comum em `configuration.nix` e um arquivo por
maquina em `hosts/`.

    generic   sistema sem NVIDIA
    nvidia    sistema com NVIDIA

O nome do host deve bater com o alvo do flake. Assim o alias `update` usa
automaticamente `#generic` na maquina sem NVIDIA e `#nvidia` na maquina com
NVIDIA.

Os arquivos de hardware ficam em `hosts/<nome>/hardware-configuration.nix`.
O restante da configuracao comum e compartilhado pelos dois sistemas.

Para uma maquina nova, copie `hosts/generic` ou `hosts/nvidia`, substitua o
`hardware-configuration.nix` pelo arquivo gerado nessa maquina e adicione o novo
alvo em `flake.nix` se precisar de outro perfil.

## 2) Primeira build em uma maquina

Depois de instalar o NixOS minimal pelo instalador grafico, mantenha o arquivo
de hardware gerado pela instalacao. Ele contem os UUIDs corretos do disco,
filesystem de boot, modulos do initrd e microcode.

Escolha o perfil antes de rodar:

    generic  maquina sem NVIDIA
    nvidia   maquina com NVIDIA

    nix-shell -p git
    git clone https://github.com/LucasMinikel/nixos-config.git ~/nixos-config
    cd ~/nixos-config
    cp /etc/nixos/hardware-configuration.nix hosts/<perfil>/hardware-configuration.nix
    git add hosts/<perfil>/hardware-configuration.nix
    sudo nixos-rebuild boot --flake .#<perfil>
    sudo reboot

Depois do primeiro boot com a config nova:

    cd ~/nixos-config
    sudo nixos-rebuild switch --flake .#<perfil>

Se quiser validar antes de aplicar:

    nixos-rebuild build --flake .#<perfil>

## 3) Aplicar mudancas no sistema

Fluxo padrão quando editar arquivos .nix:

    cd /home/lucas/nixos-config
    git add .
    sudo nixos-rebuild switch --flake .#$(hostname)

Se quiser validar antes de aplicar:

    cd /home/lucas/nixos-config
    git add .
    nixos-rebuild build --flake .#$(hostname)

## 4) Checar estado do git

    cd /home/lucas/nixos-config
    git status
    git diff

Commit rapido:

    git add .
    git commit -m "Mensagem do commit"

## 5) Hyprland e tema

Recarregar config do Hyprland:

    hyprctl reload

Reabrir Thunar apos alteracoes de tema:

    pkill thunar
    thunar &

## 6) Discos (Plex no perfil nvidia)

Listar montagens dos discos:

    findmnt | grep -E "HD-A|HD-B"

Conferir conteudo nos pontos de montagem usados:

    ls -la /mnt
    ls -la /mnt/HD-A
    ls -la /mnt/HD-B

## 7) Comandos de diagnostico rapido

DNS e rede:

    resolvectl status
    nmcli general status

Servicos importantes:

    systemctl status plex --no-pager -l

Erros da ultima rebuild:

    journalctl -b -p err --no-pager | tail -n 100

## 8) Servidor de jogos/midia (nvidia) - primeira instalacao

Esse perfil (Steam Big Picture via gamescope, KDE, retrogaming) ainda esta so
na branch `nvidia-gaming-media-server`, nao foi mergeada na `main`.

Numa maquina nvidia formatada do zero com NixOS minimal:

    nix-shell -p git
    git clone -b nvidia-gaming-media-server https://github.com/LucasMinikel/nixos-config.git ~/nixos-config
    cd ~/nixos-config
    sudo nixos-generate-config --show-hardware-config > hosts/nvidia/hardware-configuration.nix

Como a maquina foi formatada, os discos tem UUID novo. Confira/ajuste com
`lsblk -f` ou `blkid` em `hosts/nvidia/default.nix`:

    boot.loader.grub.device
    fileSystems."/mnt/HD-A" e "/mnt/HD-B"

Primeiro switch, com flakes habilitado na mao (o minimal ainda nao tem isso
configurado por padrao):

    sudo nixos-rebuild switch --flake .#nvidia --extra-experimental-features "nix-command flakes"
    sudo reboot

Depois do primeiro boot ja sobe direto no Steam Big Picture (gamescope) via
SDDM com autologin. Passos manuais que ficam de fora do Nix:

    sudo passwd lucas   # login local, hoje so tem chave SSH configurada
    # logar na Steam
    # abrir o Steam ROM Manager uma vez e apontar pra /home/lucas/Discos/HD-B/ROMs
    # colocar as BIOS em /home/lucas/Discos/HD-B/ROMs/bios
    # conferir Plex e parear Sunshine/Moonlight

Dai em diante o alias `update` funciona normal, ja que
`networking.hostName = "nvidia"` bate com `$(hostname)`.
