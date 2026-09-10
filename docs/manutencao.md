# Manutenção (Lucas)

Fora do README de propósito: quem instala não programa.

- Este repo é o marketplace (`alison`) e o plugin (`alison-plugin`) ao mesmo tempo;
  id de instalação `alison-plugin@alison`.
- Mudou algo: sobe `version` em `.claude-plugin/plugin.json`, `claude plugin validate .`,
  push; quem instalou roda `claude plugin update alison-plugin`.
- Teste local sem instalar: `claude --plugin-dir ~/Projetos/alison-plugin` (as conexões
  aparecem em `/mcp`; `claude mcp list` só enxerga plugin instalado, então o
  `check-connections.sh` reporta `missing` nesse modo).
- Teste da guarda e do `.gitignore` global, em repo e HOME descartáveis (23 casos, ~5 s):
  `scripts/test-github-guard.sh`. Novo padrão em `scripts/patterns/` pede um caso novo ali.
- Teste do parser sem instalar, contra qualquer plugin já instalado:
  `PLUGIN_NAME=stripe SERVERS=stripe scripts/check-connections.sh`.
- É uma cópia reduzida do `stl-plugin` (`docs/decisions/001-...`); o que foi removido e
  por quê está lá. Decisões em `docs/decisions/` — `ls` é o índice.

## O que não foi testado pelo Lucas (2026-09-10)

- **O fluxo inteiro da skill no app, ponta a ponta.** Testado em pedaços: o passo
  do GitHub e o dos conectores foram corrigidos a partir de relatos de campo
  (AD-008, AD-009), mas ninguém rodou `/alison-plugin:comecar` do início ao fim
  numa conta nova depois disso.

- **Windows / app desktop.** Os hooks chamam `bash "${CLAUDE_PLUGIN_ROOT}/…"`
  para rodar no Git Bash; a expansão de `${CLAUDE_PLUGIN_ROOT}` com barras
  invertidas dentro de aspas em bash MSYS não foi verificada numa máquina Windows.
  Teste: instalar no app, abrir sessão nova e ver se a linha `alison-plugin: …`
  aparece; depois pedir "commite este arquivo" com um `.env` para ver a guarda.
- **Sondagem por tool** (AD-005): depende dos nomes das tools dos servidores
  oficiais (`get_me`, `list_organizations`, `list_teams`…); a skill diz "use a que
  existir", então um rename do lado deles degrada para "não achei", não para erro.
