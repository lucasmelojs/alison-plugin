# 003 — Uma skill só, e ela pergunta em exatamente quatro momentos

**Status:** aceito · **Data:** 2026-09-10

## Contexto
O `stl-plugin` divide o onboarding em `stl-setup` (global) e `stl-project-init`
(por repo) e faz perguntas de stack, gate e deploy. Para quem não programa, cada
pergunta custa confiança, e "deu certo?" depois de um login no navegador é a
pior delas: a pessoa não sabe.

## Decisão
Uma skill, `comecar`, com as perguntas fixadas no próprio texto:

1. **Contas** — em quais serviços já existe conta (multi-select), só na primeira vez.
2. **Falha** — só quando `check-connections.sh` diz que a conexão não apareceu
   depois do login; as opções são os diagnósticos comuns.
3. **Regras** — só se já existe um `~/.claude/CLAUDE.md`.
4. Não há quarta pergunta no fim: a skill termina com uma leitura real de cada
   conta e três sugestões de uso; encerrar o turno é o convite.

Todo o resto é verificado sem perguntar. Desde o AD-005 a verificação primária é
**sondar uma tool** do servidor; `check-connections.sh` ficou como atalho opcional.
Ele lê `claude mcp list`, cujas linhas de servidor de plugin têm o formato estável
`plugin:<plugin>:<servidor>: <url> (HTTP) - ✔ Connected | ! Needs authentication`
(medido em 2026-09-10 com o plugin `stripe` instalado). O hook `SessionStart`
**não** chama `claude mcp list` — o health check leva segundos e o hook tem 5 s —
e lê só o `~/.claude/alison/config.json` que a skill grava.

## Consequências
- Quem escreve a skill não pode acrescentar pergunta sem editar este AD.
- Em modo `--plugin-dir` (teste local) o script reporta `missing`, porque
  `claude mcp list` só enxerga plugin instalado; o README avisa.
- Se o formato de `claude mcp list` mudar, o parser quebra fechado
  (`failed`), e a skill cai na pergunta 2 em vez de mentir "conectado".
