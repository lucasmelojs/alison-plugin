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
