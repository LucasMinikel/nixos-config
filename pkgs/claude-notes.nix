{ writeShellApplication, jq, git, coreutils }:

# Notas de progresso por repositório e branch, fora do repositório (não entram
# no git e funcionam em worktrees). A skill `progresso` escreve; o hook de
# SessionStart só avisa, em uma linha, que existem notas para a branch atual.

let
  # Caminho das notas para um diretório: <repo>/<branch>.md. O nome do repo vem
  # do diretório git comum, então todos os worktrees do mesmo repo coincidem.
  notesPath = ''
    notes_path() {
      local dir="$1" common repo branch
      common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
      repo="$(basename "$(dirname "$common")")"
      branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
      [ -n "$branch" ] || return 1
      printf '%s/claude-notes/%s/%s.md\n' "''${XDG_DATA_HOME:-$HOME/.local/share}" "$repo" "''${branch//\//__}"
    }
  '';

  cli = writeShellApplication {
    name = "claude-notes";
    runtimeInputs = [ git coreutils ];
    text = ''
      ${notesPath}
      cmd="''${1:-path}"
      if ! path="$(notes_path "$PWD")"; then
        echo "fora de um repositório git ou sem branch (HEAD destacado)" >&2
        exit 1
      fi
      case "$cmd" in
        path) mkdir -p "$(dirname "$path")"; echo "$path" ;;
        show) if [ -f "$path" ]; then cat "$path"; else echo "sem notas: $path" >&2; exit 1; fi ;;
        rm) rm -f "$path" && echo "removido: $path" ;;
        list) find "$(dirname "$(dirname "$path")")" -name '*.md' -printf '%TY-%Tm-%Td  %p\n' 2>/dev/null | sort -r ;;
        *) echo "uso: claude-notes [path|show|rm|list]" >&2; exit 2 ;;
      esac
    '';
  };

  # Nunca falha nem imprime nada além do aviso: a saída vira contexto da sessão.
  hook = writeShellApplication {
    name = "claude-notes-hook";
    runtimeInputs = [ jq git coreutils ];
    text = ''
      ${notesPath}
      cwd="$(jq -r '.cwd // empty' 2>/dev/null)" || cwd=""
      [ -n "$cwd" ] || exit 0
      path="$(notes_path "$cwd")" || exit 0
      if [ -f "$path" ]; then
        printf 'Há notas de progresso desta branch em %s (%s linhas, atualizadas em %s). Se a tarefa continua, leia antes de explorar o código; se for outra tarefa, ignore.\n' \
          "$path" "$(wc -l < "$path")" "$(date -r "$path" +%Y-%m-%d)"
      fi
      exit 0
    '';
  };
in
{
  inherit cli hook;
}
