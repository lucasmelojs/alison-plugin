# alison-plugin — Claude Code conectado ao GitHub, Supabase e Vercel

Um plugin que liga o Claude Code às suas contas do **GitHub** (onde o código mora),
do **Supabase** (banco de dados) e da **Vercel** (onde o site fica no ar) — por
login no navegador, sem copiar chave nenhuma e sem instalar mais nada. Feito para
quem não programa.

## Instalar (uma vez, dentro do próprio Claude Code)

Serve para o **app do Claude Code** (Mac ou Windows) e para o terminal. Abra uma
conversa e digite estas duas linhas, uma de cada vez, na caixa de mensagem:

```
/plugin marketplace add lucasmelojs/alison-plugin
/plugin install alison-plugin@alison
```

Depois digite `/reload-plugins`. Se as conexões não aparecerem em `/mcp`, feche a
conversa e abra uma nova — o app carrega as conexões e as proteções do plugin ao
iniciar a sessão.

> **Windows:** instale antes o [Git para Windows](https://git-scm.com/download/win).
> O próprio Claude Code precisa dele para executar comandos; sem ele, a guarda e a
> lista de ignorados deste plugin não funcionam.

Na primeira conversa depois disso, digite:

```
/alison-plugin:comecar
```

A skill conduz o resto: pergunta em quais serviços você já tem conta, conecta um
por vez (você só faz login no navegador e clica em **Authorize**), confere sozinha
se deu certo usando a conexão e termina mostrando algo real de cada conta. Leva
uns cinco minutos. Se parar no meio, o Claude lembra na próxima conversa e
`/alison-plugin:comecar` retoma só o que faltou.

Quem prefere o terminal: `claude plugin marketplace add lucasmelojs/alison-plugin`
e `claude plugin install alison-plugin@alison` fazem o mesmo.

## O que vem dentro

| componente | arquivo | para quê |
|---|---|---|
| conexão `github` | `.mcp.json` | servidor oficial do GitHub (`api.githubcopilot.com/mcp/`), login OAuth |
| conexão `supabase` | `.mcp.json` | servidor oficial hospedado do Supabase (`mcp.supabase.com/mcp`), login OAuth |
| conexão `vercel` | `.mcp.json` | servidor oficial da Vercel (`mcp.vercel.com`), login OAuth |
| skill `comecar` | `skills/comecar/` | o onboarding guiado — a única skill do plugin |
| `check-connections.sh` | `scripts/` | atalho opcional: lê `claude mcp list` quando o comando existe; a skill confere as conexões **usando-as** (uma consulta só de leitura), então funciona no app mesmo sem o comando |
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

**Já conectei o GitHub / Supabase / Vercel pelos Conectores do claude.ai.** Então
o Claude já usa essas conexões; a skill reconhece e não pede login de novo.

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
