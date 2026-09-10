# 002 — Supabase entra pelo MCP oficial hospedado, com OAuth

**Status:** aceito · **Data:** 2026-09-10

## Contexto
No `stl-plugin` o Supabase é self-hosted e ficou fora do MCP (AD-002 de lá): o
único servidor com OAuth é o hospedado, e a doc diz que ele não serve para
instalação própria. Aqui o pedido é explicitamente o **oficial**, e o público usa
supabase.com.

## Decisão
`.mcp.json` aponta para `https://mcp.supabase.com/mcp` com a lista completa de
`features` que a própria doc sugere para o Claude Code (docs, account, database,
debugging, development, functions, branching), autenticado por OAuth (dynamic
client registration) via `/mcp` → Authenticate. Sem `project_ref` e sem
`read_only`: a apresentação precisa mostrar o Claude criando tabela e projeto, e o
escopo por projeto desligaria as tools de conta que listam o que a pessoa tem. O
freio é comportamental, no `CLAUDE.md` global: toda criação, alteração ou exclusão
exige mostrar antes e esperar um "sim".

## Consequências
- Cloud-only: Supabase self-hosted fica fora deste plugin, e o README diz isso.
- Quem for usar em produção com dados reais deve trocar a URL por uma com
  `project_ref=<id>&read_only=true` — a doc recomenda e este AD registra o
  caminho; é uma decisão futura, não uma exceção.
- Recursos de `branching` exigem plano pago do Supabase; a tool existe, o erro
  vem do serviço.

Verificado em 2026-09-10 na doc oficial (`supabase.com/docs/guides/getting-started/mcp`).
