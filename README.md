# apresentacao-plugin — Claude Code conectado ao GitHub, Supabase e Vercel

Um plugin que liga o Claude Code às suas contas do **GitHub** (onde o código mora),
do **Supabase** (banco de dados) e da **Vercel** (onde o site fica no ar) — por
login no navegador, sem copiar chave nenhuma e sem instalar mais nada. Feito para
quem não programa.

## Instalar (3 comandos, uma vez)

Antes: ter o [Claude Code](https://docs.anthropic.com/pt/docs/claude-code/overview)
instalado. No app ou no terminal onde o Claude Code roda:

```bash
claude plugin marketplace add lucasmelojs/apresentacao-plugin
claude plugin install apresentacao-plugin@apresentacao
claude
```

Na primeira conversa, digite:

```
/apresentacao-plugin:comecar
```

A skill conduz o resto: pergunta em quais serviços você já tem conta, conecta um
por vez (você só faz login no navegador e clica em **Authorize**), confere sozinha
se deu certo e termina mostrando algo real de cada conta. Leva uns cinco minutos.
Se parar no meio, o Claude lembra na próxima conversa e `/apresentacao-plugin:comecar`
retoma só o que faltou.

## O que vem dentro

| componente | arquivo | para quê |
|---|---|---|
| conexão `github` | `.mcp.json` | servidor oficial do GitHub (`api.githubcopilot.com/mcp/`), login OAuth |
| conexão `supabase` | `.mcp.json` | servidor oficial hospedado do Supabase (`mcp.supabase.com/mcp`), login OAuth |
| conexão `vercel` | `.mcp.json` | servidor oficial da Vercel (`mcp.vercel.com`), login OAuth |
| skill `comecar` | `skills/comecar/` | o onboarding guiado — a única skill do plugin |
| `check-connections.sh` | `scripts/` | lê `claude mcp list` e diz o estado de cada conexão; a skill confere em vez de perguntar |
| hook `SessionStart` | `hooks/hooks.json` → `scripts/session-start.sh` | uma linha lembrando o que falta, enquanto faltar |
| regras globais | `templates/CLAUDE.global.md` | instalado em `~/.claude/CLAUDE.md`: fala simples, confirma antes de mudar algo, nunca lida com chave |
| guarda `github-guard` | `hooks/hooks.json` → `scripts/github-guard.sh` + `scripts/patterns/` | bloqueia chave/senha e pergunta antes de dado pessoal ir para o GitHub, por `git` ou pela conexão |
| ignorados globais | `templates/gitignore.global` → `scripts/install-git-protections.sh` | `.env` e arquivos de chave fora de todo repositório da máquina |

## O que não sobe para o GitHub sem você ver

Quatro camadas, da mais silenciosa para a mais visível. Nenhuma depende de você
lembrar de algo.

| camada | como funciona | quando age |
|---|---|---|
| **1. Lista de ignorados da máquina** | `comecar` grava um `.gitignore` global (`git config core.excludesFile`) com duas famílias: o que não pode vazar (`.env`, `*.pem`, `*.key`, `credentials.json`…) e o que ninguém precisa (`node_modules/`, `.next/`, `dist/`, `build/`, caches, logs, `.DS_Store`…). Nada disso entra em repositório nenhum, nem com `git add .` | sempre, em silêncio |
| **2. Guarda antes do envio** | o hook `github-guard` roda antes de todo `git commit`/`git push` e de toda escrita pela conexão GitHub. Chave, senha ou arquivo de credencial → **bloqueia** e explica. Planilha, exportação de banco, CPF, cartão, lista de e-mails, arquivo gerado (`node_modules`, build, cache, log) forçado para dentro, ou arquivo acima de 10 MB → **pergunta**, mostrando os nomes | a cada envio |
| **3. Regras do Claude** | o `CLAUDE.md` instalado manda listar os arquivos antes de enviar, adicionar pelo nome (nunca `git add .`), e proíbe contornar a guarda | em toda conversa |
| **4. Confirmação para mudar** | criar, alterar ou apagar qualquer coisa nos três serviços exige mostrar antes e esperar um "sim" | em toda ação que muda algo |

O que a guarda reconhece está em `scripts/patterns/*.txt` (uma expressão por
linha). É uma rede para os casos comuns, não um scanner forense: chave inventada
com formato inédito passa; a camada 3 e a 4 existem para isso.

## Perguntas comuns

**Onde ficam minhas senhas?** Em lugar nenhum daqui. O login acontece no site de
cada serviço, no seu navegador; o Claude Code guarda só uma autorização que você
pode revogar a qualquer momento nas configurações da sua conta (GitHub → *Settings
→ Applications*; Supabase → *Account → Access Tokens / Authorized apps*; Vercel →
*Settings → Authentication*).

**Como desconectar?** Digite `/mcp`, escolha a conexão e **Clear authentication**.
Ou revogue no site do serviço, como acima.

**O Claude pode apagar algo sem eu saber?** As regras instaladas mandam ele mostrar
antes o que vai mudar e esperar um "sim" para qualquer criação, alteração ou
exclusão. Consultas e listagens ele faz direto.

**Uso Supabase instalado no meu próprio servidor.** Este plugin fala com o Supabase
na nuvem (supabase.com). Para instalação própria, a Supabase não oferece login por
navegador — veja `docs/decisions/002-supabase-oficial-hospedado-com-oauth.md`.

## Manter (Lucas)

- Este repo é o marketplace (`apresentacao`) e o plugin (`apresentacao-plugin`) ao
  mesmo tempo; id de instalação `apresentacao-plugin@apresentacao`.
- Mudou algo: sobe `version` em `.claude-plugin/plugin.json`, `claude plugin
  validate .`, push; quem instalou roda `claude plugin update apresentacao-plugin`.
- Teste local sem instalar: `claude --plugin-dir ~/Projetos/apresentacao-plugin`
  (as conexões aparecem em `/mcp`; `claude mcp list` só enxerga plugin instalado,
  então o `check-connections.sh` reporta `missing` nesse modo).
- Teste da guarda e do `.gitignore` global, em repo e HOME descartáveis (23 casos,
  ~5 s): `scripts/test-github-guard.sh`. Novo padrão em `scripts/patterns/` pede
  um caso novo ali.
- Teste do parser sem instalar, contra qualquer plugin já instalado:
  `PLUGIN_NAME=stripe SERVERS=stripe scripts/check-connections.sh`.
- É uma cópia reduzida do `stl-plugin` (`docs/decisions/001-...`); o que foi
  removido e por quê está lá. Decisões em `docs/decisions/` — `ls` é o índice.
