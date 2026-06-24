throw ''
  Substitua este arquivo pelo hardware-configuration.nix gerado no notebook.

  No ASUS Vivobook, depois de clonar este repo:

    cp /etc/nixos/hardware-configuration.nix hosts/vivobook/hardware-configuration.nix

  Esse arquivo contem os UUIDs dos discos, modulos de boot e microcode corretos
  da instalacao atual. Ele precisa ser especifico da maquina.
''
