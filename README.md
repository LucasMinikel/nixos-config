# NixOS Config - Guia Rapido de Comandos

Este repositório usa flakes e Home Manager para manter o sistema declarativo.

## 1) Hosts disponiveis

Este repositório tem uma base comum em `configuration.nix` e um arquivo por
maquina em `hosts/`.

    nixos     desktop atual, com NVIDIA, Plex e discos extras
    vivobook  ASUS Vivobook X1504V, sem NVIDIA

O nome do host deve bater com o alvo do flake. Assim o alias `update` usa
automaticamente `#nixos` no desktop e `#vivobook` no notebook.

## 2) Primeira build no ASUS Vivobook

Depois de instalar o NixOS minimal pelo instalador grafico, mantenha o arquivo
de hardware gerado pela instalacao. Ele contem os UUIDs corretos do disco,
filesystem de boot, modulos do initrd e microcode.

    nix-shell -p git
    git clone -b vivobook-x1504v https://github.com/LucasMinikel/nixos-config.git ~/nixos-config
    cd ~/nixos-config
    cp /etc/nixos/hardware-configuration.nix hosts/vivobook/hardware-configuration.nix
    git add hosts/vivobook/hardware-configuration.nix
    sudo nixos-rebuild boot --flake .#vivobook
    sudo reboot

Depois do primeiro boot com a config nova:

    cd ~/nixos-config
    sudo nixos-rebuild switch --flake .#vivobook

Se quiser validar antes de aplicar:

    nixos-rebuild build --flake .#vivobook

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

## 6) Discos (Plex)

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
