# 006 — O plugin assume o app do Claude Code como única superfície

**Status:** aceito · **Data:** 2026-09-10 (mesclado na `main`; a branch de teste foi apagada)

## Contexto
O AD-005 fez o plugin funcionar no app desktop *também*, mantendo o terminal
como alternativa. Lucas pediu uma variante que funcione **somente** no app do
Claude Code, sem apagar o que existe — daí uma branch, para o testador
instalar e comparar antes de qualquer merge.

## Decisão
Provado em teste de campo e mesclado. O plugin passa a ser só do app:
- README e skill falam só do app: instalação por `/plugin …` na caixa de mensagem,
  `/mcp` na mesma caixa, `/reload-plugins` e sessão nova. Nenhuma menção a
  terminal ou `claude …`.
- A skill perde o "atalho opcional" `check-connections.sh`. O arquivo **fica** no
  repo, com cabeçalho dizendo que é ferramenta de terminal para manutenção — nada
  é apagado.
- Hooks, guarda e `.gitignore` global não mudam. O `.mcp.json` **saiu** nesta
  branch no mesmo dia — ver AD-007: o plugin deixou de trazer servidores.

## Consequências
- Substitui o AD-005 no que diz respeito ao terminal: ele deixa de ser caminho
  alternativo documentado.
- Quem usa o terminal continua conseguindo instalar (`claude plugin install`), mas
  a skill fala com quem está no app; nada no plugin depende da CLI.
- Aprendido ao testar por branch: `/plugin marketplace add <git-url>#<branch>`
  funciona, e o nome do marketplace vem do `marketplace.json` — duas origens com
  o mesmo nome (`alison`) colidem na mesma máquina, então testar uma branch exige
  remover o marketplace da `main` antes.
