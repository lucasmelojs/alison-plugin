# 005 — Tem que funcionar no app desktop, onde não há `claude` no PATH

**Status:** aceito · **Data:** 2026-09-10

## Contexto
O primeiro teste real foi no app desktop do Claude Code, em Windows. Relato do
testador: "não há um binário `claude` acessível via PowerShell aqui". Tudo o que
o plugin apoiava na CLI quebrou de uma vez: a instalação por `claude plugin …`,
o `check-connections.sh` (que lê `claude mcp list`) e, por extensão, a skill,
que mandava "reiniciar" quando o script falhava. O público-alvo usa o app, não o
terminal — "precisamos que funcione principalmente lá".

## Decisão
1. **Instalação pelo chat**: `/plugin marketplace add lucasmelojs/alison-plugin`
   e `/plugin install alison-plugin@alison`, depois `/reload-plugins` e sessão
   nova. A CLI vira alternativa no README, não o caminho.
2. **Conexão verificada por uso, não por CLI**: a skill sonda cada servidor com
   uma tool só de leitura (`get_me`, `list_organizations`, `list_teams`…). Tool
   ausente ou erro de autenticação = `needs_auth`. Funciona em qualquer
   superfície porque as tools são a própria sessão. Conector do claude.ai para o
   mesmo serviço conta como conectado — ninguém loga duas vezes.
   `check-connections.sh` fica como atalho opcional; sua falha é ignorada.
3. **Nenhum `python3` no caminho crítico**: `session-start.sh` passa a `grep`; o
   registro `~/.claude/alison/config.json` é escrito pela skill com a tool Write.
   Windows de fábrica não tem `python3`.
4. **Hooks com `bash` explícito** (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh"`),
   para o Git Bash executar o `.sh` no Windows, onde não há bit de execução nem
   shebang honrado pelo shell padrão.
5. **Git for Windows é pré-requisito declarado** no README. Sem ele o Claude Code
   usa PowerShell e nada em bash roda — inclusive a guarda. É a mesma exigência
   que a doc do Claude Code faz para a aba Code.

## Consequências
- O que a skill sabe sobre conexão vem de tentar usar; se um servidor renomear a
  tool de sondagem, a skill degrada para "não achei" e cai na pergunta 2 — não
  mente "conectado".
- Windows não foi testado pelo Lucas; `docs/manutencao.md` lista o que conferir.
- `claude mcp list` continua a única forma de ver o estado **sem** gastar uma
  chamada de tool; por isso o script fica, mas nunca bloqueia o fluxo.
