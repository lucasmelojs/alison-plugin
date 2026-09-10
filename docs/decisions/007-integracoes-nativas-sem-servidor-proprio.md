# 007 — O plugin não traz servidor: conduz às integrações nativas do app

**Status:** em teste (branch `feat/desktop-only`) · **Data:** 2026-09-10
**A parte de GitHub foi substituída pelo AD-009** (credencial local primeiro; nuvem opcional).

## Contexto
No primeiro teste do login, o app devolveu *"Não foi possível iniciar o login para
github: Algo deu errado"*. Causa medida: o servidor MCP remoto do GitHub
(`api.githubcopilot.com/mcp/`) aponta `authorization_servers: github.com/login/oauth`,
que não publica metadados OAuth nem `registration_endpoint` — sem registro
dinâmico de cliente, um cliente genérico não inicia o fluxo. A doc oficial do
github-mcp-server para Claude diz literalmente *"Claude Code does not support
OAuth for the remote server"* e manda colar um PAT no header. Supabase
(`api.supabase.com`) e Vercel (`vercel.com/api/login/oauth/register`) têm
registro dinâmico; o GitHub não. Lucas então pediu: "conduzir os usuários a usar
a integração nativa dos apps".

## Decisão
O plugin **deixa de trazer `.mcp.json`**. A skill `comecar` conduz ao que o app
já tem:
- **Supabase e Vercel**: Conectores do claude.ai, ligados **de dentro da sessão**
  pela tool `authenticate` do próprio conector (AD-008); o cartão **+** →
  **Connectors** só entra quando o conector nem existe na conta. Ambos estão no
  diretório oficial (verificado em claude.com/connectors, 2026-09-10) e aparecem
  no Claude Code como `claude.ai Supabase` / `claude.ai Vercel`.
- **GitHub**: não está no diretório de conectores. O caminho nativo tem duas
  metades: **Connect GitHub** em claude.ai/code (Claude GitHub App, para o que
  roda na nuvem) e **GitHub Desktop** para enviar arquivos deste computador — o
  app do próprio GitHub faz o login e configura a credencial do Git; `gh auth
  login --web` quando o `gh` existir. Nunca token colado.
- Verificação continua por uso (AD-005) para Supabase e Vercel. GitHub não tem
  tool para sondar: ganha **uma pergunta de confirmação** (ASK #1b, "seus
  repositórios apareceram?"), registrada aqui como exceção ao AD-003, mais
  `gh auth status` quando houver `gh`.
- A guarda permanece; o matcher MCP vira `mcp__.*[Gg]it[Hh]ub.*__.*` para pegar
  qualquer ferramenta GitHub que o app venha a expor.

## Consequências
- Zero configuração de servidor no plugin: o que ele entrega é condução, regras e
  proteção. Se o Claude ganhar um conector de GitHub, a skill passa a sondá-lo
  sem mudar o resto.
- A `main` (v0.2.0) ainda traz o `.mcp.json` com o GitHub que não loga; se esta
  branch for aprovada, o merge corrige a `main`; se não, a `main` precisa ao
  menos tirar o servidor `github`.
- Dependência de plano: Conectores e claude.ai/code exigem conta claude.ai
  (Pro/Max/Team/Enterprise) — o público do plugin já está no app, logo já tem.
