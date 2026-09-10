# 001 — Cópia do stl-plugin reduzida a três conexões e uma skill

**Status:** aceito · **Data:** 2026-09-10 · **Renomeado** de `apresentacao-plugin` para `alison-plugin` em 2026-09-10 (repo, marketplace `alison`, pasta e todos os identificadores)

## Contexto
Lucas pediu uma cópia do `stl-plugin` adaptada para pessoas não-técnicas, com as
conexões GitHub, Supabase (oficial) e Vercel e uma skill que amarre o processo. O
`stl-plugin` carrega o processo de desenvolvimento STLFLIX inteiro: sete skills de
dev (spec-driven, green-gate, atomic-commit, security-check, smart-dispatch,
handoff, design system), templates de repo e o MCP `firecrawl`, que exige API key
na instalação.

## Decisão
Repo próprio em `~/Projetos/alison-plugin`, marketplace `alison` e
plugin `alison-plugin` no mesmo repo (mesmo desenho do AD-001 do
`stl-plugin`). Nome de marketplace diferente de `stlflix` para os dois poderem
coexistir na máquina do Lucas. Ficam: os três MCPs HTTP com OAuth, a skill
`comecar`, o hook `SessionStart` e um `CLAUDE.md` global em linguagem simples.
Saem: todas as skills de dev, `stl-project-init`, os templates de `.gitignore`,
`CLAUDE.project.md` e `handoff.md`, e o `firecrawl` (uma chave para copiar é
exatamente a fricção que o público não pode ter; `userConfig` sai junto).

> **Atualização (AD-010):** o Firecrawl voltou. Ele ganhou login por navegador e
> está no diretório de conectores do claude.ai, então a razão da remoção — a API
> key — não existe mais.

## Consequências
- Zero toolchain: só MCPs HTTP, então não há `node`, `npx`, `gh` nem `supabase`
  a instalar — o pré-requisito é o Claude Code e um navegador.
- O `CLAUDE.md` global instalado é de comportamento (fala simples, confirma antes
  de mudar, nunca lida com chave), não de processo de código.
- Quem cruzar para desenvolvimento de verdade instala o `stl-plugin`; este não
  cresce nessa direção.
