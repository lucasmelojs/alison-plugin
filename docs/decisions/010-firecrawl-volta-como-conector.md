# 010 — Firecrawl volta, agora como conector com login por navegador

**Status:** aceito · **Data:** 2026-09-10
**Reverte** a remoção do Firecrawl decidida no AD-001.

## Contexto
O AD-001 tirou o `firecrawl` que vinha do `stl-plugin` por um motivo só: ele
exigia colar uma API key na instalação, o que é exatamente a fricção que este
público não pode ter. Lucas notou a ausência: *"e o firecrawl não está sendo
conectado durante o processo"*.

Medido em 2026-09-10, o motivo da remoção deixou de existir:
- Firecrawl passou a expor `https://mcp.firecrawl.dev/v2/mcp-oauth`, com login
  por navegador. O servidor de autorização (`https://www.firecrawl.dev`) publica
  `registration_endpoint`, ou seja, tem registro dinâmico de cliente — que é
  justamente o que falta no GitHub (AD-007) e faz o login lá falhar.
- Mais importante: **Firecrawl está no diretório de conectores do claude.ai**
  (verificado em claude.com/connectors). Então nem servidor próprio é preciso.

## Decisão
Firecrawl entra como o **quarto** conector, tratado igual a Supabase e Vercel:
aparece como `claude.ai Firecrawl`, é ligado pela tool `authenticate` de dentro
da sessão (AD-008) e é detectado pelos nomes das tools. Nada de `.mcp.json`, o
AD-007 continua valendo. Ordem no fluxo: Supabase → Vercel → Firecrawl → GitHub.

Uma regra própria: **a presença das tools basta como prova**. Diferente dos
outros, sondar o Firecrawl custa crédito do plano grátis, então a skill não gasta
uma busca só para conferir. O único gasto é uma busca na demonstração final.

## Consequências
- O plano grátis do Firecrawl tem limite diário; se a pessoa esbarrar nele, a
  falha vem do serviço e não da conexão. A skill não trata isso como desconectado.
- Fica um caminho paralelo à busca nativa do Claude Code, que continua existindo.
  Firecrawl entra quando o trabalho é ler páginas e extrair dado estruturado.
- Se o conector sair do diretório, o caminho alternativo é o `.mcp.json` com a
  URL `mcp-oauth`, que também funciona sem chave — mas aí reabre o AD-007.
