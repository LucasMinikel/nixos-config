# Experimentos de uso do Claude Code

Registro das mudanças feitas para reduzir consumo e melhorar o trabalho com o Claude Code, com a linha de base de cada uma e o critério para manter ou retirar. Revisão marcada para **2026-12-15**.

## Como medir

Todas as métricas saem das transcrições locais (só contagens, nenhum conteúdo):

```bash
# medianas por sessão num período, filtrando o cwd por regex
claude-usage-backfill --metrics 2026-11-16 2026-12-15 'siga|3gjor1d6'

# uma linha por sessão (calls, reads, tokens, custo, tempo)
claude-usage --sessions siga

# skills, subagentes, MCP e ferramentas registrados pelo hook
claude-usage
```

`cache lido por turno` é o melhor indicador do tamanho do contexto: é o que cada turno relê do cache. Filtros de projeto: os worktrees do Paseo do SIGA ficam em `~/.paseo/worktrees/3gjor1d6/`, os do memora em `33wvtbnk/`.

## Linha de base (2026-10-16 a 2026-11-15)

| Filtro | Sessões | Turnos | Calls | Bash | Reads | Cache lido por turno | Cache lido total |
| :- | -: | -: | -: | -: | -: | -: | -: |
| todos | 129 | 56 | 27 | 23 | 0 | 95,1 mil | 8.558 M |
| `siga\|3gjor1d6` | 115 | 61 | 30 | 26 | 1 | 100,3 mil | 7.367 M |
| `caso-zero` | 1 | 2.942 | 1.557 | 1.072 | 80 | 321,9 mil | 947 M |
| `memora\|33wvtbnk` | 1 | 555 | 240 | 139 | 6 | 256,7 mil | 143 M |

Valores de turnos, calls, bash e reads são medianas por sessão. Em `caso-zero` e `memora` há uma sessão só, então não servem como linha de base estatística.

## Experimentos

### 1. Monitoramento local (`claude-usage`)
- **O que é:** hook `PostToolUse`/`PostToolUseFailure` em `/etc/claude-code/managed-settings.d/50-claude-usage.json`, que grava só identificadores em `~/.local/share/claude-usage/tools.jsonl`. Ativo desde 2026-10-30.
- **Manter se:** for usado para decidir os outros itens desta lista.
- **Retirar:** remover `./modules/claude-usage.nix` do `configuration.nix`.

### 2. `AGENTS.md` do SIGA com `docs/agents` sob demanda
- **O que é:** branch `chore/agents-md-lazy-docs` (commit `d327de46c`, worktree `~/projects/siga-agents-lean`). Contexto fixo por sessão cai de ~130 KB para ~15 KB.
- **Estado:** aguardando PR e merge. A medição só começa depois do merge.
- **Previsão:** cache lido por turno no SIGA cair de ~100 mil para ~70 mil (−29 mil tokens).
- **Manter se:** a queda aparecer e os PRs continuarem passando no `qa-review` sem regras de `docs/agents` esquecidas.
- **Retirar se:** a qualidade cair. Basta reverter o commit.

### 3. Poda de skills
- **O que é:** `deploying-to-cloud`, `paseo-plugin`, `paseo-loop`, `paseo-committee` e `paseo-advisor` movidas para `~/.claude/skills-removidas-20261115/`.
- **Manter se:** nenhuma delas fizer falta (`claude-usage` não mostra tentativa de uso) e o Paseo não as reinstalar.
- **Retirar:** mover a pasta de volta para `~/.claude/skills/`.

### 4. `CLAUDE.md` em `caso-zero` e `memora`
- **O que é:** branches `chore/claude-md` (caso-zero) e `chore/claude-md-contexto` (memora), já no GitHub.
- **Manter se:** as sessões nesses projetos tiverem menos exploração (calls e bash por sessão) que a linha de base. Com poucas sessões, a avaliação é qualitativa.

### 5. Notas de progresso (`progresso` + `claude-notes`)
- **O que é:** skill `progresso`, CLI `claude-notes` e hook `SessionStart` (drop-in `51-claude-notes.json`). Notas em `~/.local/share/claude-notes/<repo>/<branch>.md`.
- **Medir:** quantas vezes a skill foi usada (`claude-usage`, Skills), quantas notas existem (`claude-notes list`), e se sessões que retomam uma tarefa com notas têm menos calls que a linha de base.
- **Manter se:** for usada pelo menos algumas vezes por semana e as sessões retomadas explorarem menos.
- **Retirar se:** ninguém usar. Tirar o `home.file` da skill no `home.nix` e o drop-in `51-claude-notes.json` do módulo.

## Decisões

| Data | Experimento | Decisão | Motivo |
| :- | :- | :- | :- |
| | | | |
