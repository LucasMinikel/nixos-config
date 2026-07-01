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

  antigravity =
    let
      version = "2.2.1";
      build = "5287492581195776";
      runtimeDependencies = with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libdrm
        libgbm
        libGL
        libxkbcommon
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        mesa
        nspr
        nss
        pango
        systemd
      ];
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "antigravity";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${version}-${build}/linux-x64/Antigravity.tar.gz";
        hash = "sha256-prp3BG+SqhziHYoMZ0lUca9MK+EbpiTl2TWCGWmyCYk=";
      };

      icon = pkgs.fetchurl {
        url = "https://antigravity.google/assets/image/antigravity-logo.png";
        hash = "sha256-jwuV0tIdv5MLTRAOL9xFBWc+kApzGqVupjOktZwxJ5k=";
      };

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        copyDesktopItems
        makeWrapper
      ];

      buildInputs = runtimeDependencies;

      desktopItems = [
        (pkgs.makeDesktopItem {
          name = "antigravity";
          desktopName = "Antigravity";
          comment = "Experience liftoff";
          genericName = "Agentic Platform";
          exec = "antigravity %U";
          icon = "antigravity";
          categories = [
            "Development"
            "Utility"
          ];
          startupNotify = false;
          startupWMClass = "Antigravity";
        })
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/opt/Antigravity" "$out/bin" "$out/share/applications" "$out/share/pixmaps"
        cp -r . "$out/opt/Antigravity/"

        install -Dm644 "$icon" "$out/share/pixmaps/antigravity.png"

        cat > "$out/opt/Antigravity/antigravity-launcher" <<'EOF'
        #!/bin/sh
        set -eu

        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Antigravity"
        lock_target="$(readlink "$config_dir/SingletonLock" 2>/dev/null || true)"
        running_pid="''${lock_target##*-}"

        if [ -n "$running_pid" ] && [ "$running_pid" != "$lock_target" ] && kill -0 "$running_pid" 2>/dev/null; then
          if ${pkgs.hyprland}/bin/hyprctl clients -j 2>/dev/null | ${pkgs.ripgrep}/bin/rg -q "\"pid\": ?$running_pid"; then
            exec "$out/opt/Antigravity/antigravity" "$@"
          fi

          ${pkgs.procps}/bin/pkill -TERM -P "$running_pid" 2>/dev/null || true
          kill -TERM "$running_pid" 2>/dev/null || true
          sleep 1
          kill -KILL "$running_pid" 2>/dev/null || true
          rm -f "$config_dir/SingletonLock" "$config_dir/SingletonSocket" "$config_dir/SingletonCookie"
        fi

        exec "$out/opt/Antigravity/antigravity" "$@"
        EOF
        substituteInPlace "$out/opt/Antigravity/antigravity-launcher" \
          --replace-fail '$out' "$out"
        chmod +x "$out/opt/Antigravity/antigravity-launcher"

        makeWrapper "$out/opt/Antigravity/antigravity-launcher" "$out/bin/antigravity" \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies} \
          --set-default NIXOS_OZONE_WL 1

        runHook postInstall
      '';

      meta = {
        description = "Google Antigravity 2.0 multi-agent orchestration platform";
        homepage = "https://antigravity.google/product/antigravity-2";
        license = lib.licenses.unfree;
        mainProgram = "antigravity";
        platforms = [ "x86_64-linux" ];
      };
    };

  paseo =
    let
      version = "0.1.102";
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

      src = pkgs.fetchurl {
        url = "https://github.com/getpaseo/paseo/releases/download/v0.1.102/Paseo-0.1.102-amd64.deb";
        hash = "sha256-4tO4z9xJttq25ah4vfJdBmdyXNtOSww5X50l2xoa0uE=";
      };

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
      version = "1.4.114";
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

      src = pkgs.fetchurl {
        url = "https://github.com/stablyai/orca/releases/download/v1.4.114/orca-ide_1.4.114_amd64.deb";
        hash = "sha256-QLdgw4fHlIZsS5cfxN4fcrYnqIhteWJKGSBucoldfXk=";
      };

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

  claude-code =
    let
      version = "2.1.185";
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "claude-code";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/linux-x64/claude";
        hash = "sha256-4SRjOGmfBO4OYn3uP21O16C6tI4FFL3mnG2tQ7wwOVI=";
      };

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        makeWrapper
      ];

      buildInputs = with pkgs; [
        stdenv.cc.cc.lib
        zlib
      ];

      dontUnpack = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/claude"
        runHook postInstall
      '';

      postFixup = ''
        wrapProgram "$out/bin/claude" \
          --argv0 claude \
          --set DISABLE_AUTOUPDATER 1 \
          --set DISABLE_INSTALLATION_CHECKS 1 \
          --set-default DISABLE_NON_ESSENTIAL_MODEL_CALLS 1 \
          --set DISABLE_TELEMETRY 1 \
          --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
      '';

      meta = {
        description = "Anthropic's terminal-based AI coding agent";
        homepage = "https://claude.ai";
        license = lib.licenses.unfree;
        mainProgram = "claude";
        platforms = [ "x86_64-linux" ];
      };
    };
in

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    unzip
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
    antigravity
    paseo
    orca-ide
    claude-code
  ];
}
