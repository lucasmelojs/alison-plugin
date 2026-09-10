# 004 — Quatro camadas para nada sensível chegar ao GitHub sem a pessoa ver

**Status:** aceito · **Data:** 2026-09-10

## Contexto
O público não sabe o que é `.env`, não lê `git status` e responde "sim" ao que o
Claude propuser. Uma regra em prosa no `CLAUDE.md` é conselho para um modelo que
esquece (medido no `~/.claude/CLAUDE.md` do Lucas: a regra "nunca na main" era
violada onde estava mais carregada). A barreira tem que ser código, e a pessoa
tem que **ver** quando ela age.

## Decisão
Quatro camadas, cada uma cobrindo a falha da anterior:

1. **`.gitignore` global** (`core.excludesFile`), instalado por
   `scripts/install-git-protections.sh` na skill, sem pergunta. Cobre o `git add .`
   que a camada 3 proíbe mas o modelo pode fazer mesmo assim. Só nomes de arquivo,
   em duas famílias: segredo (`.env*`, chaves) e **gerado** — `node_modules/`,
   `.next/`, `dist/`, `build/`, `out/`, `coverage/`, caches, logs, `.DS_Store`.
   Pedido do Lucas em 2026-09-10: o desnecessário também não sobe.
2. **Hook `PreToolUse` `github-guard.sh`** em dois matchers: `Bash` (só age se o
   comando tem `git … commit|push`) e `mcp__plugin_alison[-_]plugin_github__.*`
   (toda escrita pela conexão). Dois níveis: **BLOCK** (`exit 2`, motivo em stderr)
   para segredo — chave privada, tokens GitHub/Stripe/Anthropic/OpenAI/Slack/Google,
   `sb_secret_`, `SERVICE_ROLE_KEY`, URL de banco com senha, `*.env`, `*.pem` —
   e **CONFIRM** (`permissionDecision: "ask"`) para dado pessoal — CPF, cartão,
   JWT, ≥5 e-mails distintos, planilhas, dumps, arquivo gerado forçado para dentro
   (`scripts/patterns/filenames-noise.txt`) e arquivo acima de 10 MB. O "ask" é a caixa nativa do Claude
   Code com o motivo escrito: é o momento em que a pessoa percebe.
3. **Regras no `CLAUDE.md` global**: listar arquivos antes, adicionar pelo nome,
   nunca contornar a guarda (`--no-verify`, renomear, colar em outro lugar).
4. **Confirmação para toda mudança** nos três serviços (já existia, AD-002).

Padrões em `scripts/patterns/*.txt`, um por linha, `grep -E -i`. No caminho do
MCP o payload JSON bruto é varrido como um documento — os tokens sobrevivem ao
escape, e assim não há dependência de `python3` (que em Mac sem ferramentas de
desenvolvedor abre um diálogo de instalação). `python3` só entra para ler o
`command` do Bash, e nesse caminho `git` já implica as ferramentas instaladas.

## Consequências
- É rede para o caso comum, não gitleaks: segredo com formato inédito passa pela
  camada 2 e depende da 3 e da 4. O README diz isso.
- `git add` com caminho específico é superaproximado: a guarda varre todo untracked
  e modificado quando vê `add` ou `commit -a`. Pode gerar um "ask" por arquivo que
  não ia subir; preferimos o falso "pergunta" ao falso "passou".
- `.sql` **não** está em CONFIRM de propósito: migração é rotina em projeto
  Supabase, e uma caixa a cada commit ensina a pessoa a clicar "sim" sem ler.
- Esta é a quinta pergunta possível numa sessão, mas pertence à guarda, não à
  skill — o AD-003 continua valendo para a `comecar`.
- Ignorar `dist/`, `build/`, `out/` e `target/` **globalmente** esconde uma pasta
  de código que por acaso tenha esse nome. Para este público é troca aceita; quem
  cair nisso usa `git add -f` e a guarda pergunta uma vez.
- Limite de 500 arquivos lidos por dentro (nomes são todos conferidos); acima
  disso vira um CONFIRM dizendo quantos ficaram sem leitura.
