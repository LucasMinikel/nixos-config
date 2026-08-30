{ lib, pkgs, ... }:

let
  sources = pkgs.callPackage ../_sources/generated.nix { };

  claude-code =
    let
      version = sources.claude-code.version;
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "claude-code";
      inherit version;

      src = sources.claude-code.src;

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
  environment.systemPackages = [ claude-code ];
}
