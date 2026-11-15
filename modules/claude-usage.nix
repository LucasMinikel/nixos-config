{ pkgs, ... }:

let
  claude-usage = pkgs.callPackage ../pkgs/claude-usage.nix { };

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
  ];

  # Registrado como managed settings (drop-in) em vez de mexer no
  # ~/.claude/settings.json, que o Claude Code e o Orca reescrevem e por isso
  # precisa continuar gravável. Os hooks de todos os escopos são mesclados.
  # Trade-off: o hook vale para todas as contas, não dá para desligar por
  # usuário (nem com disableAllHooks) e só muda via `update`.
  environment.etc."claude-code/managed-settings.d/50-claude-usage.json".text = builtins.toJSON {
    hooks = {
      PostToolUse = [ { hooks = [ hookCommand ]; } ];
      PostToolUseFailure = [ { hooks = [ hookCommand ]; } ];
    };
  };
}
