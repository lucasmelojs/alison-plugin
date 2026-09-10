# alison-plugin — as integrações nativas do app do Claude Code, para quem não programa

Um plugin para o **app do Claude Code** (Mac ou Windows) que **conduz** quem não
programa a ligar as integrações que já existem no app — **Supabase** e **Vercel**
pelos Conectores do claude.ai, **GitHub** pelo Claude GitHub App e pelo GitHub
Desktop — e que protege para nada sensível ou desnecessário subir ao GitHub. O
plugin não traz servidor nenhum: nada para copiar, nenhuma chave, só logins no
navegador.

## Instalar (uma vez, dentro do app)

Abra o app do Claude Code, comece uma conversa e digite estas duas linhas, uma de
cada vez, na caixa de mensagem:

```
/plugin marketplace add lucasmelojs/alison-plugin
/plugin install alison-plugin@alison
```

Depois digite `/reload-plugins` e abra uma conversa nova — o app carrega as
proteções do plugin ao iniciar a sessão.

> **Windows:** instale antes o [Git para Windows](https://git-scm.com/download/win).
> O próprio Claude Code precisa dele para executar comandos; sem ele, a guarda e a
> lista de ignorados deste plugin não funcionam.

Na primeira conversa depois disso, digite:

```
/alison-plugin:comecar
```

A skill conduz o resto: pergunta em quais serviços você já tem conta, liga uma
integração por vez sem você sair do app (para Supabase e Vercel ele mesmo abre o
pedido de login e te dá o link; para o GitHub ele confere a credencial da máquina e
só pede o **GitHub Desktop** se faltar), confere sozinha se deu certo usando a conexão e termina mostrando
algo real de cada conta. Leva
uns cinco minutos. Se parar no meio, o Claude lembra na próxima conversa e
`/alison-plugin:comecar` retoma só o que faltou.

## O que vem dentro

| componente | arquivo | para quê |
|---|---|---|
| Conectores Supabase e Vercel | (do próprio app, nada no plugin) | o Claude inicia o login na própria conversa e te dá o link; aparecem como `claude.ai Supabase` / `claude.ai Vercel` |
| GitHub | (do próprio app, nada no plugin) | a credencial desta máquina: **GitHub Desktop** (ou `gh`). O Claude confere sozinho e só pede login se faltar |
| skill `comecar` | `skills/comecar/` | o onboarding guiado — a única skill do plugin |
| `check-connections.sh` | `scripts/` | **não usado no app**: ferramenta de terminal mantida para quem mantém o plugin (lê `claude mcp list`); a skill confere as conexões **usando-as**, com uma consulta só de leitura |
| hook `SessionStart` | `hooks/hooks.json` → `scripts/session-start.sh` | uma linha lembrando o que falta, enquanto faltar |
| regras globais | `templates/CLAUDE.global.md` | instalado em `~/.claude/CLAUDE.md`: fala simples, confirma antes de mudar algo, nunca lida com chave |
| guarda `github-guard` | `hooks/hooks.json` → `scripts/github-guard.sh` + `scripts/patterns/` | bloqueia chave/senha e pergunta antes de dado pessoal ir para o GitHub, por `git` ou por qualquer ferramenta GitHub que o app venha a ter |
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

**Já conectei o Supabase ou a Vercel pelos Conectores do claude.ai.** Então está
feito; a skill reconhece e não pede login de novo.

**Por que o GitHub é diferente?** Não existe conector de GitHub no diretório do
Claude, e o servidor do GitHub exige colar um token — coisa que este plugin nunca
pede. O que vale para quem trabalha em pastas do próprio computador é a credencial
da máquina: o app **GitHub Desktop** faz o login e configura tudo. O Claude confere
se já existe e, se existir, não pede nada.

**Já conectei o GitHub e ele pede de novo?** Não deve mais: a skill mede a
credencial antes de falar. Se acontecer, é bug — abra uma issue com o que apareceu.

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
