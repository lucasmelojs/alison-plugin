# 008 — O login do conector começa na sessão, não no claude.ai

**Status:** em teste (branch `feat/desktop-only`) · **Data:** 2026-09-10

## Contexto
Rodando a skill no app, ela mandou o testador para "claude.ai → Configurações →
Conectores". Reação dele: *"ele está me movendo para os conectores padrões, mas eu
preciso usar no claude code, não no chat"*. A skill estava certa no destino
(conectores nativos) e errada no caminho: tirava a pessoa do app.

## Decisão
Todo conector do claude.ai instalado mas sem login expõe, na própria sessão, o par
de tools `mcp__claude_ai_<Nome>__authenticate` e `__complete_authentication`. A
primeira devolve a URL de autorização; depois que a pessoa autoriza no navegador,
as tools reais aparecem sozinhas. Em sessão remota, a URL `http://localhost:…/callback`
que falha ao carregar é colada de volta em `complete_authentication`.

A skill passa a:
1. **Ler o estado pelos nomes das tools**: tools reais = ligado; só `authenticate`
   = falta login; nenhuma = conector não adicionado à conta.
2. **Começar o login ela mesma** chamando `authenticate` e entregando o link (2A).
3. Só quando não há tool nenhuma, pedir **+ → Connectors → Usar** dentro do app (2B).
4. claude.ai vira último recurso explícito (2C), depois de 2B falhar duas vezes.

Regra fixada no cabeçalho da skill: *nunca mande a pessoa para o claude.ai*.

## Consequências
- O caminho feliz não sai do app: a pessoa clica num link e volta.
- Depende do par `authenticate`/`complete_authentication` existir. Se sumir, a
  skill degrada para 2B (o cartão de conectores), que é o caminho manual.
- O cartão **Seus conectores** com o botão **Usar** é o que o app mostra em 2B;
  o texto da skill usa esses rótulos.
