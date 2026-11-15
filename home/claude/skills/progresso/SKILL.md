---
name: progresso
description: Salva ou retoma as notas de progresso da tarefa atual (o que foi descoberto, decisões, o que falta) para a próxima sessão não refazer a exploração. Use quando o usuário pedir para salvar o progresso, antes de /clear, ao encerrar uma sessão com a tarefa inacabada, ou quando o início da sessão avisar que existem notas desta branch.
---

# Notas de progresso

As notas ficam fora do repositório, uma por repo e branch. `claude-notes path` imprime o caminho (e cria a pasta); `claude-notes show` mostra o conteúdo; `claude-notes rm` apaga.

## Retomar

Leia as notas com `claude-notes show`. Trate o conteúdo como ponto de partida, não como verdade: confira no código o que for usar antes de agir, porque o código pode ter mudado.

## Salvar

Rode `claude-notes path` e escreva o arquivo inteiro (substitua o anterior) com este formato, em no máximo 60 linhas:

```markdown
# <tarefa em uma linha>

## Objetivo
<o que o usuário quer e o critério de pronto>

## Descobertas
- <fato verificado, com caminho:linha>

## Decisões
- <decisão e o motivo>

## Feito
- <o que já está implementado ou commitado>

## Próximos passos
1. <próxima ação concreta>

## Não fazer
- <caminhos já testados que não funcionaram, e por quê>
```

Regras:
- Só fatos verificados nesta sessão. Marque o que for suposição.
- Prefira `caminho:linha` a trechos de código.
- Nunca escreva segredos, tokens, senhas, conteúdo de `.env` nem dados pessoais (de candidatos, clientes, crianças etc.).

## Concluir

Quando a tarefa terminar (merge feito ou abandonada), rode `claude-notes rm`.
