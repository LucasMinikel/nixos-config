{ lib, pkgs, ... }:

let
  sources = pkgs.callPackage ../../_sources/generated.nix { };

  codex-latest =
    let
      version = sources.codex.version;
      platform = "linux-x64";
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "codex";
      inherit version;

      src = sources.codex.src;

      platformPackage = sources.codex-linux-x64.src;

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

  paseo =
    let
      version = sources.paseo.version;
      runtimeDependencies = with pkgs; [
        alsa-lib
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libayatana-appindicator
        libcap_ng
        libdrm
        libgbm
        libGL
        libnotify
        libsecret
        libuuid
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libXtst
        mesa
        nspr
        nss
        pango
        libseccomp
        systemd
      ];
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "paseo";
      inherit version;

      src = sources.paseo.src;

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        dpkg
        makeWrapper
      ];

      buildInputs = runtimeDependencies;

      dontConfigure = true;
      dontBuild = true;

      unpackPhase = ''
        runHook preUnpack
        dpkg-deb --fsys-tarfile "$src" | tar --no-same-owner --no-same-permissions -xf -
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin" "$out/lib" "$out/share"
        cp -r opt/Paseo "$out/lib/"

        if [ -d usr/share/applications ]; then
          cp -r usr/share/applications "$out/share/"
        fi

        if [ -d usr/share/icons ]; then
          cp -r usr/share/icons "$out/share/"
        fi

        substituteInPlace "$out/share/applications/Paseo.desktop" \
          --replace-fail "/opt/Paseo/Paseo" "$out/bin/paseo"

        makeWrapper "$out/lib/Paseo/Paseo" "$out/bin/paseo" \
          --add-flags --no-sandbox \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}:$out/lib/Paseo \
          --prefix PATH : ${lib.makeBinPath [
            pkgs.glib
            pkgs.gnome-keyring
            pkgs.trash-cli
            pkgs.xdg-utils
          ]} \
          --set-default NIXOS_OZONE_WL 1

        runHook postInstall
      '';

      meta = {
        description = "Unified interface to orchestrate and manage AI coding agents";
        homepage = "https://paseo.sh/";
        license = lib.licenses.mit;
        mainProgram = "paseo";
        platforms = [ "x86_64-linux" ];
      };
    };

  orca-ide =
    let
      version = sources.orca-ide.version;
      runtimeDependencies = with pkgs; [
        alsa-lib
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libayatana-appindicator
        libcap_ng
        libdrm
        libgbm
        libGL
        libnotify
        libsecret
        libuuid
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libXtst
        mesa
        nspr
        nss
        pango
        libseccomp
        systemd
      ];
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "orca-ide";
      inherit version;

      src = sources.orca-ide.src;

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        dpkg
        makeWrapper
      ];

      buildInputs = runtimeDependencies;

      dontConfigure = true;
      dontBuild = true;

      unpackPhase = ''
        runHook preUnpack
        dpkg-deb --fsys-tarfile "$src" | tar --no-same-owner --no-same-permissions -xf -
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin" "$out/lib" "$out/share"
        cp -r opt/Orca "$out/lib/"

        if [ -d usr/share/applications ]; then
          cp -r usr/share/applications "$out/share/"
        fi

        if [ -d usr/share/icons ]; then
          cp -r usr/share/icons "$out/share/"
        fi

        substituteInPlace "$out/share/applications/orca-ide.desktop" \
          --replace-fail "/opt/Orca/orca-ide" "$out/bin/orca-ide"

        makeWrapper "$out/lib/Orca/orca-ide" "$out/bin/orca-ide" \
          --add-flags --no-sandbox \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}:$out/lib/Orca \
          --prefix PATH : ${lib.makeBinPath [
            pkgs.glib
            pkgs.gnome-keyring
            pkgs.trash-cli
            pkgs.xdg-utils
          ]} \
          --set-default NIXOS_OZONE_WL 1

        runHook postInstall
      '';

      meta = {
        description = "Agent Development Environment for running coding agents in parallel";
        homepage = "https://www.onorca.dev/";
        license = lib.licenses.mit;
        mainProgram = "orca-ide";
        platforms = [ "x86_64-linux" ];
      };
    };

in

{
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    # Desktop Hyprland
    thunar
    awww
    waybar
    wofi
    bubblewrap
    grim
    slurp
    blueman
    networkmanagerapplet
    brightnessctl

    # Apps pessoais
    libreoffice
    qbittorrent
    google-chrome
    moonlight-qt

    # Dev
    gh
    nodejs
    docker-compose
    vscode
    codex-latest
    navicat-mysql
    paseo
    orca-ide
  ];
}
