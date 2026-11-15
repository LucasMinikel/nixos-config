{ lib, writeShellApplication, jq, findutils, coreutils, util-linux }:

# Monitoramento local de uso do Claude Code (skills, subagentes, MCP e
# ferramentas nativas). Nada sai da máquina e nada além de identificadores é
# gravado: nunca tool_input, comandos, conteúdo de arquivos ou prompts.

let
  # Sempre sai com 0: um erro aqui jamais pode atrapalhar o Claude.
  hook = writeShellApplication {
    name = "claude-usage-hook";
    runtimeInputs = [ jq coreutils ];
    excludeShellChecks = [ "SC2016" ]; # $ dentro do programa jq, entre aspas simples
    text = ''
      umask 077
      dir="''${XDG_DATA_HOME:-$HOME/.local/share}/claude-usage"
      mkdir -p "$dir" 2>/dev/null || true

      # "detail" só recebe o nome da skill ou o tipo do subagente.
      jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        def short: if type == "string" then .[0:120] else null end;
        (.tool_name // "") as $tool
        | { ts: $ts,
            event: (.hook_event_name // ""),
            session_id: (.session_id // ""),
            cwd: (.cwd // ""),
            account: (((.transcript_path // "") | split("/projects/") | (.[0] // ""))
                      | split("/") | (last // "")
                      | if . == ".claude" or . == "" then "default" else . end),
            tool_name: $tool,
            detail: (
              if $tool == "Skill" then (.tool_input.skill // .tool_input.skill_name)
              elif ($tool == "Agent" or $tool == "Task" or $tool == "Subagent")
                then (.tool_input.subagent_type // .tool_input.agent_type)
              else null end | short) }
        | select(.tool_name != "")
        | with_entries(select(.value != null))
      ' >> "$dir/tools.jsonl" 2>/dev/null || true

      exit 0
    '';
  };

  # Lê as transcrições existentes e emite registros no mesmo formato do hook
  # (só identificadores). Com --tokens, resume o consumo de tokens por projeto.
  backfill = writeShellApplication {
    name = "claude-usage-backfill";
    runtimeInputs = [ jq findutils coreutils util-linux ];
    excludeShellChecks = [ "SC2016" ]; # $ dentro do programa jq, entre aspas simples
    text = ''
      mode="''${1:-records}"

      dirs=()
      for d in "$HOME/.claude" "$HOME"/.claude-accounts/*; do
        [ -d "$d/projects" ] && dirs+=("$d")
      done
      if [ ''${#dirs[@]} -eq 0 ]; then
        echo "nenhuma transcrição encontrada" >&2
        exit 0
      fi

      transcripts() {
        find "''${dirs[@]}" -path '*/projects/*' -name '*.jsonl' -print0
      }

      # Medianas por sessão num período, para comparar antes/depois de uma
      # mudança: --metrics <desde AAAA-MM-DD> [até AAAA-MM-DD] [regex-de-cwd]
      if [ "$mode" = "--metrics" ]; then
        since="''${2:?uso: --metrics <desde> [até] [filtro]}"
        until="''${3:-9999-12-31}"
        filter="''${4:-}"
        transcripts | xargs -0 cat | jq -rn --arg since "$since" --arg until "$until" --arg f "$filter" '
          def med: sort | if length == 0 then null
                          elif length % 2 == 1 then .[length / 2 | floor]
                          else (.[length / 2 - 1] + .[length / 2]) / 2 end;
          def r1: if . == null then "-" else ((. * 10 | round) / 10) end;
          reduce (inputs | select(.type == "assistant" and (.sessionId // "") != ""
                                  and (.timestamp // "")[0:10] >= $since
                                  and (.timestamp // "")[0:10] <= $until
                                  and ((.cwd // "") | test($f)))) as $l ({};
            ($l.message.content | if type == "array" then map(select(.type == "tool_use")) else [] end) as $t
            | .[$l.sessionId].turns += 1
            | .[$l.sessionId].cache += ($l.message.usage.cache_read_input_tokens // 0)
            | .[$l.sessionId].calls += ($t | length)
            | .[$l.sessionId].bash += ([$t[] | select(.name == "Bash")] | length)
            | .[$l.sessionId].reads += ([$t[] | select(.name == "Read")] | length))
          | [.[]] as $s
          | "periodo: \($since) a \($until)   filtro: \(if $f == "" then "(nenhum)" else $f end)",
            "sessoes: \($s | length)",
            "mediana por sessao:  turnos \($s | map(.turns) | med | r1)   calls \($s | map(.calls) | med | r1)   bash \($s | map(.bash // 0) | med | r1)   reads \($s | map(.reads // 0) | med | r1)",
            "mediana de cache lido por turno (mil tokens, ~tamanho do contexto): \($s | map(.cache / .turns / 1000) | med | r1)",
            "total de cache lido (M): \($s | map(.cache) | add // 0 | . / 1000000 | r1)"
        '
        exit 0
      fi

      if [ "$mode" = "--tokens" ]; then
        transcripts | xargs -0 cat | jq -rn '
          def m: ((. / 1000000 * 10 | round) / 10);
          reduce (inputs | select(.type == "assistant")) as $l ({};
            ($l.cwd // "?") as $k
            | ($l.message.usage // {}) as $u
            | ($l.message.content | if type == "array" then . else [] end) as $c
            | .[$k].s[$l.sessionId // "?"] = 1
            | .[$k].msgs += 1
            | .[$k].cache_read += ($u.cache_read_input_tokens // 0)
            | .[$k].cache_create += ($u.cache_creation_input_tokens // 0)
            | .[$k].output += ($u.output_tokens // 0)
            | .[$k].bash += ([$c[] | select(.type == "tool_use" and .name == "Bash")] | length)
            | .[$k].graph += ([$c[] | select(.type == "tool_use" and (.name | test("codegraph|graphify"; "i")))] | length))
          | to_entries | sort_by(-.value.cache_read)
          | (["sessoes","turnos","cache_lido(M)","cache_gravado(M)","saida(M)","bash","codegraph/graphify","projeto"] | @tsv),
            (.[:25][] | [(.value.s | length), .value.msgs, (.value.cache_read | m),
                         (.value.cache_create | m), (.value.output | m),
                         .value.bash, (.value.graph // 0), .key] | @tsv)
        ' | column -t -s "$(printf '\t')"
        exit 0
      fi

      # Uma linha por sessão, com as mesmas colunas de um benchmark A/B:
      # chamadas, leituras de arquivo, tokens, tempo e custo. Só contagens.
      if [ "$mode" = "--sessions" ]; then
        filter="''${2:-}"
        transcripts | xargs -0 jq -rn --arg f "$filter" '
          def m: ((. / 1000000 * 10 | round) / 10);
          def n: ((. * 10 | round) / 10);
          reduce inputs as $l ({};
            ($l.sessionId // "") as $s
            | (input_filename | split("/projects/")[0] | split("/") | last
               | if . == ".claude" then "default" else . end) as $acc
            | if $s == "" then .
              elif $l.type == "cost-state" then
                .[$s].cost = ($l.totalCostUSD // .[$s].cost)
                | .[$s].api = ($l.totalAPIDuration // .[$s].api)
                | .[$s].dur = ($l.totalDuration // .[$s].dur)
              elif $l.type == "assistant" then
                ($l.message.usage // {}) as $u
                | ($l.message.content | if type == "array" then . else [] end
                   | map(select(.type == "tool_use"))) as $t
                | .[$s].acc = $acc
                | .[$s].cwd = (.[$s].cwd // $l.cwd)
                | .[$s].last = ([.[$s].last // $l.timestamp, $l.timestamp] | max)
                | .[$s].turns += 1
                | .[$s].cache_read += ($u.cache_read_input_tokens // 0)
                | .[$s].output += ($u.output_tokens // 0)
                | .[$s].calls += ($t | length)
                | .[$s].reads += ([$t[] | select(.name == "Read")] | length)
                | .[$s].bash += ([$t[] | select(.name == "Bash")] | length)
                | .[$s].skill += ([$t[] | select(.name == "Skill")] | length)
                | .[$s].agent += ([$t[] | select(.name | IN("Agent", "Task", "Subagent"))] | length)
                | .[$s].mcp += ([$t[] | select(.name | startswith("mcp__"))] | length)
                | .[$s].graph += ([$t[] | select(.name | test("codegraph|graphify"; "i"))] | length)
                | reduce ($t[] | select(.name == "Read") | .input.file_path // empty) as $p
                    (.; .[$s].files[$p] = 1)
              else . end)
          | to_entries
          | map(select(.value.turns != null and ((.value.cwd // "") | contains($f))))
          | sort_by(.value.last) | reverse | .[:30]
          | (["data","conta","projeto","turnos","calls","reads","arq_unicos","bash","skill","agent","mcp","graph","cache_lido(M)","saida(M)","custo_usd","tempo_min","api_min"] | @tsv),
            (.[] | .value as $v | [
              $v.last[0:10], $v.acc, ($v.cwd | split("/") | last), $v.turns, $v.calls,
              ($v.reads // 0), (($v.files // {}) | length), ($v.bash // 0), ($v.skill // 0),
              ($v.agent // 0), ($v.mcp // 0), ($v.graph // 0),
              ($v.cache_read | m), ($v.output | m),
              (if $v.cost then ($v.cost | n) else "-" end),
              (if $v.dur then ($v.dur / 60000 | n) else "-" end),
              (if $v.api then ($v.api / 60000 | n) else "-" end)] | @tsv)
        ' | column -t -s "$(printf '\t')"
        exit 0
      fi

      transcripts | xargs -0 jq -c '
        select(.type == "assistant") as $l
        | (input_filename | split("/projects/")[0] | split("/") | last
           | if . == ".claude" then "default" else . end) as $acc
        | ($l.message.content | if type == "array" then .[] else empty end)
        | select(.type == "tool_use")
        | { ts: $l.timestamp, event: "history", session_id: $l.sessionId,
            cwd: $l.cwd, account: $acc, tool_name: .name,
            detail: (if .name == "Skill" then .input.skill
                     elif (.name == "Agent" or .name == "Task" or .name == "Subagent")
                       then .input.subagent_type
                     else null end) }
        | with_entries(select(.value != null))
      '
    '';
  };

  usage = writeShellApplication {
    name = "claude-usage";
    runtimeInputs = [ jq coreutils util-linux backfill ];
    excludeShellChecks = [ "SC2016" ]; # $ dentro do programa jq, entre aspas simples
    text = ''
      if [ "''${1:-}" = "--sessions" ]; then
        shift
        exec claude-usage-backfill --sessions "$@"
      fi

      usage() {
        echo "uso: claude-usage [--history] [arquivo.jsonl ...]"
        echo "     claude-usage --sessions [filtro-de-projeto]   (uma linha por sessão)"
        echo "  sem argumentos lê ~/.local/share/claude-usage/tools.jsonl"
        echo "  --history  usa as transcrições em ~/.claude/projects (retroativo)"
        echo "  copie o tools.jsonl de outro host e passe o arquivo para somar"
      }

      log="''${XDG_DATA_HOME:-$HOME/.local/share}/claude-usage/tools.jsonl"
      data="$(mktemp)"
      trap 'rm -f "$data"' EXIT

      history=0
      files=()
      for a in "$@"; do
        case "$a" in
          --history) history=1 ;;
          -h|--help) usage; exit 0 ;;
          *) files+=("$a") ;;
        esac
      done

      if [ "$history" = 1 ]; then
        claude-usage-backfill > "$data"
      else
        [ ''${#files[@]} -eq 0 ] && files=("$log")
        if ! cat "''${files[@]}" > "$data" 2>/dev/null; then
          echo "sem dados em: ''${files[*]}" >&2
          exit 1
        fi
      fi

      jq -rs '
        def pad: tostring | ("      " + .) | .[-6:];
        def sec($t): "", "== " + $t + " ==";
        def count(sel; key; $order; $limit):
          [ .[] | select(sel) | {k: (key | tostring)} ]
          | group_by(.k) | map({k: .[0].k, n: length})
          | (if $order == "k" then sort_by(.k) else sort_by(-.n, .k) end)
          | (if $limit > 0 then .[:$limit] else .[$limit:] end)
          | .[] | "\(.n | pad)  \(.k)";
        def native: (.tool_name | startswith("mcp__") | not)
                    and (.tool_name != "Skill")
                    and (.tool_name | IN("Agent", "Task", "Subagent") | not);

        "registros: \(length)",
        sec("Skills mais usadas"),    count(.tool_name == "Skill"; .detail // "?"; "n"; 15),
        sec("Subagentes"),            count(.tool_name | IN("Agent", "Task", "Subagent"); .detail // "?"; "n"; 15),
        sec("Servidores MCP"),        count(.tool_name | startswith("mcp__"); .tool_name | split("__")[1]; "n"; 15),
        sec("Ferramentas nativas"),   count(native; .tool_name; "n"; 15),
        sec("Por dia (30 mais recentes)"), count(true; .ts[0:10]; "k"; -30),
        sec("Por projeto (cwd)"),     count(true; .cwd; "n"; 15),
        sec("Por conta"),             count(true; .account // "default"; "n"; 10)
      ' "$data"

      # Itens instalados que nunca apareceram nos dados.
      echo
      echo "== Skills instaladas que nunca apareceram =="
      used="$(jq -r 'select(.tool_name == "Skill") | .detail // empty' "$data" | sort -u)"
      installed="$(for d in "$HOME/.claude" "$HOME"/.claude-accounts/*; do
                     if [ -d "$d/skills" ]; then ls "$d/skills"; fi
                   done 2>/dev/null | sort -u || true)"
      comm -23 <(printf '%s\n' "$installed") <(printf '%s\n' "$used") | sed '/^$/d' | sed 's/^/  /'

      echo
      echo "== Servidores MCP configurados que nunca apareceram =="
      used_mcp="$(jq -r 'select(.tool_name | startswith("mcp__")) | .tool_name | split("__")[1]' "$data" | sort -u)"
      conf_mcp="$(jq -r '.mcpServers // {} | keys[]' "$HOME/.claude.json" "$HOME"/.claude-accounts/*/.claude.json 2>/dev/null | sort -u || true)"
      comm -23 <(printf '%s\n' "$conf_mcp") <(printf '%s\n' "$used_mcp") | sed '/^$/d' | sed 's/^/  /'
      echo "  (conectores do claude.ai e ferramentas nativas não são listáveis em disco)"
    '';
  };
in
{
  inherit hook backfill usage;
}
