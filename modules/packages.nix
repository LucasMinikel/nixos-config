{ lib, pkgs, ... }:

let
  codex-latest =
    let
      version = "0.142.4";
      platform = "linux-x64";
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "codex";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";
        hash = "sha256-ZcVgF0STQdVb46lmVN81th1DtINH7Alq+9H6sYKnsVw=";
      };

      platformPackage = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${platform}.tgz";
        hash = "sha256-PVplrOt1q7N8fo4DHbGgw00LpV1dJjxeb0MMIefebHw=";
      };

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      dontConfigure = true;
      dontBuild = true;

      unpackPhase = ''
        runHook preUnpack
        mkdir codex codex-${platform}
        tar -xzf "$src" -C codex --strip-components=1
        tar -xzf "$platformPackage" -C codex-${platform} --strip-components=1
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p \
          "$out/lib/node_modules/@openai/codex" \
          "$out/lib/node_modules/@openai/codex-${platform}" \
          "$out/bin"

        cp -r codex/. "$out/lib/node_modules/@openai/codex/"
        cp -r codex-${platform}/. "$out/lib/node_modules/@openai/codex-${platform}/"

        chmod +x "$out/lib/node_modules/@openai/codex/bin/codex.js"
        chmod +x "$out/lib/node_modules/@openai/codex-${platform}/vendor/x86_64-unknown-linux-musl/bin/codex"

        makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/codex" \
          --add-flags "$out/lib/node_modules/@openai/codex/bin/codex.js" \
          --prefix PATH : ${lib.makeBinPath [
            pkgs.bubblewrap
            pkgs.ripgrep
          ]}

        runHook postInstall
      '';

      meta = {
        description = "Lightweight coding agent that runs in your terminal";
        homepage = "https://github.com/openai/codex";
        changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${version}/CHANGELOG.md";
        license = lib.licenses.asl20;
        mainProgram = "codex";
        platforms = [ "x86_64-linux" ];
      };
    };

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
    wget
    git
    gnumake
    btop
    kitty
    thunar
    awww
    waybar
    wofi
    bubblewrap
    grim
    slurp
    wl-clipboard
    libnotify
    blueman
    networkmanagerapplet
    pavucontrol
    mpv
    libreoffice
    qbittorrent
    gh
    codex-latest
    docker-compose
    nerd-fonts.jetbrains-mono
    vscode
    google-chrome
    navicat-mysql
  ];
}
