# 006 — Branch `feat/desktop-only`: o plugin assume o app do Claude Code como única superfície

**Status:** em teste · **Data:** 2026-09-10

## Contexto
O AD-005 fez o plugin funcionar no app desktop *também*, mantendo o terminal
como alternativa. Lucas pediu uma variante que funcione **somente** no app do
Claude Code, sem apagar o que existe — daí uma branch, para o testador
instalar e comparar antes de qualquer merge.

## Decisão
Na branch `feat/desktop-only`:
- README e skill falam só do app: instalação por `/plugin …` na caixa de mensagem,
  `/mcp` na mesma caixa, `/reload-plugins` e sessão nova. Nenhuma menção a
  terminal ou `claude …`.
- A skill perde o "atalho opcional" `check-connections.sh`. O arquivo **fica** no
  repo, com cabeçalho dizendo que é ferramenta de terminal para manutenção — nada
  é apagado.
- Hooks, guarda, `.gitignore` global e sondagem por tool não mudam: já eram
  compatíveis com o app (AD-005).

## Consequências
- Instalação a partir da branch: `/plugin marketplace add` com a referência da
  branch (sintaxe registrada no README da branch). Marketplace `alison` com o
  mesmo nome na `main` e na branch conflita na mesma máquina — remover um antes
  de adicionar o outro.
- Se o teste aprovar, o merge desta branch substitui o AD-005 no que diz sobre
  terminal; se reprovar, apaga-se a branch e este AD vira "rejeitado".
