{ lib, pkgs, ... }:

let
  navicat-mysql = pkgs.navicat-premium.overrideAttrs (finalAttrs: previousAttrs: {
    pname = "navicat-mysql";
    version = "17.3.9";

    src = pkgs.appimageTools.extractType2 {
      inherit (finalAttrs) pname version;
      src = pkgs.fetchurl {
        url = "https://dn.navicat.com/download/navicat17-mysql-en-x86_64.AppImage";
        hash = "sha256-sbRs6TLFQIw9DHAOu3wSGc8po//I7/EjLNBwdnbL9Ys=";
      };
    };

    installPhase = previousAttrs.installPhase + ''
      ln -s $out/bin/navicat $out/bin/navicat-mysql
    '';

    preFixup = ''
      rm -f $out/lib/libselinux.so.1
      ln -s ${pkgs.libselinux.out}/lib/libselinux.so.1 $out/lib/libselinux.so.1

      if [ -e $out/lib/glib/libglib-2.0.so.0 ]; then
        rm $out/lib/glib/libglib-2.0.so.0
        ln -s ${pkgs.glib.out}/lib/libglib-2.0.so.0 $out/lib/glib/libglib-2.0.so.0
      fi

      for libpq in $out/lib/pq-g/libpq.so.5.5 $out/lib/pq-g/libpq_ce.so.5.5; do
        if [ -e "$libpq" ]; then
          patchelf --replace-needed libcrypt.so.1 ${pkgs.libxcrypt}/lib/libcrypt.so.2 "$libpq"
          patchelf --replace-needed libselinux.so.1 ${pkgs.libselinux.out}/lib/libselinux.so.1 "$libpq"
        fi
      done

      wrapQtApp $out/bin/navicat \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [
            pkgs.e2fsprogs
            pkgs.expat
            pkgs.fontconfig
            pkgs.freetype
            pkgs.glib
            pkgs.glibc
            pkgs.harfbuzz
            pkgs.libGL
            pkgs.libx11
            pkgs.libgpg-error
            pkgs.libselinux
            pkgs.libxcb
            pkgs.libxkbcommon
            pkgs.p11-kit
            pkgs.pango
          ]
        }:$out/lib \
        --set QT_PLUGIN_PATH $out/plugins \
        --set QT_QPA_PLATFORM xcb \
        --set QT_STYLE_OVERRIDE Fusion \
        --chdir $out
    '';

    meta = previousAttrs.meta // {
      homepage = "https://www.navicat.com/products/navicat-for-mysql";
      changelog = "https://www.navicat.com/products/navicat-for-mysql-release-note";
      description = "Database development tool for MySQL and MariaDB";
      platforms = [ "x86_64-linux" ];
      mainProgram = "navicat-mysql";
    };
  });
in

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    gnumake
    btop
    kitty
    thunar
    awww
    waybar
    wofi
    blueman
    networkmanagerapplet
    pavucontrol
    mpv
    libreoffice
    qbittorrent
    gh
    docker-compose
    nerd-fonts.jetbrains-mono
    vscode
    google-chrome
    navicat-mysql
  ];
}
