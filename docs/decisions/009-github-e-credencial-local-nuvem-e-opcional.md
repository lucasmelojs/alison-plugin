# 009 — GitHub é a credencial desta máquina; a parte na nuvem é opcional

**Status:** em teste (branch `feat/desktop-only`) · **Data:** 2026-09-10
**Substitui** a parte de GitHub do AD-007.

## Contexto
O AD-007 descreveu o GitHub como "duas metades" e pôs o Claude GitHub App
(claude.ai/code) como a primeira. No teste, Lucas já tinha conectado o GitHub e a
skill continuou mandando ele para lá: *"eu conectei o github mas ele ainda me manda
para essa url furada"*. A página é um beco quando a conexão já existe — o botão
**Connect GitHub** só aparece para quem **não** conectou; quem conectou vê a lista
de repositórios e não acha o botão que a instrução descreve.

Medido nesta máquina em 2026-09-10: `gh auth status` responde em milissegundos e
`printf 'protocol=https\nhost=github.com\n\n' | GIT_TERMINAL_PROMPT=0 git
credential fill` devolve `password=` quando existe credencial guardada, sem abrir
prompt e sem imprimir nada com `grep -q`. Ou seja, dá para **medir** em vez de
perguntar.

## Decisão
Para o público deste plugin, que trabalha em pastas do próprio computador, GitHub
é **a credencial nesta máquina**:

1. Sondar antes de falar (as duas linhas acima). Se responder, GitHub está pronto:
   uma linha e segue. **Proibido citar claude.ai/code nesse caso.**
2. Faltando credencial: `gh auth login --web` quando o `gh` existir; senão
   **GitHub Desktop** (https://desktop.github.com), que é o app oficial, faz login
   no navegador e configura a credencial do Git.
3. Se depois disso ainda não houver credencial, não insistir: avisar que o primeiro
   envio vai abrir uma janela de login e seguir com `pending`.
4. A parte na nuvem (Claude GitHub App / sessões em claude.ai/code) vira **extra
   opcional**, mencionada só se a pessoa pedir para trabalhar sem depender deste
   computador, e sempre com o condicional "**se aparecer** o botão".

Com isso cai o ASK #1b, e a skill volta às três perguntas do AD-003.

## Consequências
- A skill nunca refaz uma conexão existente, que era a falha relatada.
- A verificação do GitHub passa a ser medida, como a dos conectores (AD-005).
- `gh auth status` não é estável ao longo do tempo: nesta mesma máquina o `gh`
  estava logado no começo da sessão e deslogado no fim. Por isso duas sondas, e a
  decisão de nunca tratar "pendente" como bloqueio.
