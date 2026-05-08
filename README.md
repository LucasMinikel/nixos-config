# NixOS Config - Guia Rapido de Comandos

Este repositório usa flakes e Home Manager para manter o sistema declarativo.

## 1) Aplicar mudancas no sistema

Fluxo padrão quando editar arquivos .nix:

    cd /home/lucas/nixos-config
    git add .
    sudo nixos-rebuild switch --flake .#nixos

Se quiser validar antes de aplicar:

    cd /home/lucas/nixos-config
    git add .
    nixos-rebuild build --flake .#nixos

## 2) Checar estado do git

    cd /home/lucas/nixos-config
    git status
    git diff

Commit rapido:

    git add .
    git commit -m "Mensagem do commit"

## 3) Hyprland e tema

Recarregar config do Hyprland:

    hyprctl reload

Reabrir Thunar apos alteracoes de tema:

    pkill thunar
    thunar &

## 4) Discos (Plex)

Listar montagens dos discos:

    findmnt | grep -E "HD-A|HD-B"

Conferir conteudo nos pontos de montagem usados:

    ls -la /mnt
    ls -la /mnt/HD-A
    ls -la /mnt/HD-B

## 5) Comandos de diagnostico rapido

DNS e rede:

    resolvectl status
    nmcli general status

Servicos importantes:

    systemctl status plex --no-pager -l

Erros da ultima rebuild:

    journalctl -b -p err --no-pager | tail -n 100
