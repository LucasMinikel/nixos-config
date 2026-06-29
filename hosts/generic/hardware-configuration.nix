# Generic hardware template.
# For a real machine, replace this file with the output from nixos-generate-config.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };

  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-label/BOOT";
    fsType = lib.mkDefault "vfat";
    options = lib.mkDefault [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = lib.mkDefault [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
