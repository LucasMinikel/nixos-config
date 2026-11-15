{ pkgs, ... }:

let
  claude-usage = pkgs.callPackage ../pkgs/claude-usage.nix { };
  claude-notes = pkgs.callPackage ../pkgs/claude-notes.nix { };

  hookCommand = {
    type = "command";
    command = "${claude-usage.hook}/bin/claude-usage-hook";
    async = true;
  };
in
{
  environment.systemPackages = [
    claude-usage.usage
    claude-usage.backfill
    claude-notes.cli
  ];

  # Registrado como managed settings (drop-in) em vez de mexer no
  # ~/.claude/settings.json, que o Claude Code reescreve e por isso precisa
  # continuar gravável. Os hooks de todos os escopos são mesclados.
  # Trade-off: o hook vale para todas as contas, não dá para desligar por
  # usuário (nem com disableAllHooks) e só muda via `update`.
  environment.etc."claude-code/managed-settings.d/50-claude-usage.json".text = builtins.toJSON {
    hooks = {
      PostToolUse = [ { hooks = [ hookCommand ]; } ];
      PostToolUseFailure = [ { hooks = [ hookCommand ]; } ];
    };
  };

  # Síncrono de propósito: a saída (uma linha, só se houver notas da branch)
  # precisa chegar ao contexto no início da sessão.
  environment.etc."claude-code/managed-settings.d/51-claude-notes.json".text = builtins.toJSON {
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "${claude-notes.hook}/bin/claude-notes-hook";
            timeout = 5;
          }
        ];
      }
    ];
  };
}
