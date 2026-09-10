---
name: comecar
description: Guided, plain-language onboarding that leads a non-programmer through the NATIVE integrations of the Claude Code desktop app — claude.ai Connectors for Supabase, Vercel and Firecrawl, and the machine's own GitHub credential (GitHub Desktop) for GitHub — starting each connector login from inside the session with its own authenticate tool, and verifying by use instead of asking. No plugin-shipped servers, no keys, no terminal. Use when the SessionStart hook says the connections are not configured, on the first session after installing alison-plugin, or when the user says "começar", "conectar", "configurar", "ligar o GitHub / Supabase / Vercel / Firecrawl", "não está conectado", "o que eu consigo fazer aqui". Idempotent — re-run any time; it only touches what is still pending.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# comecar — connect GitHub, Supabase and Vercel, one at a time

The person in front of you does **not** program. They will never read a config
file, and every question you ask costs them confidence. Rules that override any
default behaviour while this skill runs:

- **Portuguese, plain words.** Never say MCP, OAuth, token, CLI, terminal, JSON or
  hook unprompted. Say "conexão", "login no navegador", "esta janela".
- **Questions happen at exactly three moments** (marked `ASK` below). Everything else
  you check yourself (probe a tool, run a script) and simply report. Never ask
  "deu certo?" — probe.
- **One service per message.** Finish GitHub before mentioning Supabase.
- **Never ask for, accept or store a password or key.** The connection is a browser
  login. If the user pastes a key, tell them kindly not to, and do not repeat it.
- **Never click for them.** The **+** button and the connector card are theirs;
  you give exact labels, one step per line.
- **Never send them to claude.ai.** Everything happens in this window. When a
  connector needs login, YOU call its `authenticate` tool and hand over the link
  it returns. claude.ai is a last resort, named only in step 2C.
- **Verify by using.** A connection is proven when one of its tools answers a
  read-only call. There is no CLI in this surface; do not look for one.

This plugin ships **no servers**. Everything comes from the app's own integrations:
Supabase, Vercel and Firecrawl are claude.ai **Connectors** (`claude.ai Supabase`,
`claude.ai Vercel`, `claude.ai Firecrawl`); GitHub is the **credential on this machine**, put there by
**GitHub Desktop** or by `gh`. GitHub has no connector and its remote server needs a
pasted token, which this audience must never do (AD-007). The Claude GitHub App on
claude.ai/code is an optional extra, never a step (AD-009).

## 0. Ground truth, silently

Order on a **first run** (no `config.json`): send the welcome of step 1 *before*
the first probe — a probe can pop the permission box, and the person must have
read that answering **Yes** is expected. On later runs, probe straight away.

The person is in the **Claude Code desktop app** (Mac or Windows). The source of
truth is whether each service's tools **answer**. Probe each one with a read-only
call:

Every claude.ai connector appears in this session as tools named
`mcp__claude_ai_<Nome>__<tool>` (`Supabase`, `Vercel`, `Firecrawl`). What you can see tells you
the state, with no question and no command:

| what the session offers | state | what step 2 does |
|---|---|---|
| real tools, e.g. `mcp__claude_ai_Supabase__list_organizations` | `connected` | nothing |
| only `mcp__claude_ai_Supabase__authenticate` (and `__complete_authentication`) | `needs_auth` | **2A** — you start the login |
| no `mcp__claude_ai_Supabase__*` at all | `missing` | **2B** — the person adds the connector |

Confirm a `connected` guess with one read-only call (`list_organizations` for
Supabase, `list_teams` or `list_projects` for Vercel). For **Firecrawl** the listed
tools are proof enough — never spend a search just to check, its free tier is
counted. A failure mentioning
authentication, 401, unauthorized or "session token rejected" means `needs_auth`,
even when the real tools are listed. Any other error → `failed`, keep the message.

GitHub has no connector. What matters for someone working on their own folders is
the **credential on this machine**, and it is probeable — never ask:

```bash
command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && echo gh_ok
printf 'protocol=https\nhost=github.com\n\n' | GIT_TERMINAL_PROMPT=0 git credential fill 2>/dev/null | grep -q '^password=' && echo credential_ok
```

Either line printed → `connected`. Neither → `needs_auth`. Never print or store what
the second command returns; `grep -q` is silent on purpose.

Also read `~/.claude/alison/config.json` (`%USERPROFILE%\.claude\alison\config.json`
on Windows) if it exists, and note whether `~/.claude/CLAUDE.md` exists.

- All four `connected` → jump to **step 5**. Nothing to ask.
- The person says a service is already connected but its tools are `missing` → the
  session started before the connection; ask them to open a **new conversation**
  and type `/alison-plugin:comecar` again. Stop.

## 1. Welcome (first run only — no `config.json`)

One message, five lines max: we will switch on four connections that already live in the
app, by logging in on the browser, about five minutes, nothing to copy; a small
permission box may appear when Claude checks a connection — answering **Yes** is
expected. Then:

**ASK #1** — AskUserQuestion, `multiSelect: true`, header `Contas`:
> "Em quais destes você já tem conta?" options: `GitHub` · `Supabase` · `Vercel`
> · `Firecrawl` · `Nenhuma ainda`. Firecrawl entra com login do GitHub e o plano
> grátis já serve — diga isso se perguntarem.

For every service without an account, give the sign-up link and one tip, then wait
for "pronto" before continuing:

| service | link | tip |
|---|---|---|
| GitHub | https://github.com/signup | create this one first |
| Supabase | https://supabase.com/dashboard/sign-up | click **Continue with GitHub** — no new password |
| Vercel | https://vercel.com/signup | click **Continue with GitHub** — no new password |
| Firecrawl | https://www.firecrawl.dev/signin/signup | **Continue with GitHub**; the free plan is enough |

If the user already has all four, skip the table entirely.

## 2. Connect, in order: Supabase → Vercel → Firecrawl → GitHub

Skip any service already `connected`. Connectors first: they are the two clicks
the person can see working immediately. GitHub last, because it has two halves.

### 2A. Connector installed, needs login — you start it (the normal case)

Applies to Supabase, Vercel and Firecrawl, one at a time, in that order.

Call the connector's own tool, e.g. `mcp__claude_ai_Supabase__authenticate`. It
returns an authorization URL. Then, in one message:

> Vamos ligar o **Supabase**. Abra este link no navegador:
> <URL que a tool devolveu>
> Entre na sua conta e clique em **Authorize**. Ele pergunta qual organização
> autorizar — escolha a sua (normalmente só existe uma). Depois volte aqui e me
> diga "pronto".

Vercel: swap the organisation line for "Se ele perguntar qual time (scope),
escolha o seu nome." Firecrawl: "Se você ainda não tem conta, dá para entrar com o
GitHub ali mesmo, e o plano grátis já serve."

When they say "pronto", **do not ask anything** — probe. The real tools appear on
their own once the browser flow finishes.

- Probe answers → "Supabase ligado ✓". Next service.
- Nothing yet → the browser may have landed on a page that fails to load, at an
  address starting with `http://localhost:`. Ask them to copy that address from
  the browser's address bar and paste it here; pass it to
  `mcp__claude_ai_Supabase__complete_authentication` as `callback_url`. Probe again.
- Still nothing after that → **ASK #2**, header with the service name:
  > "A conexão com o Supabase ainda não ligou. O que aconteceu?"
  > `A página deu erro` · `Entrei com outra conta` ·
  > `Fechei antes de autorizar — quero tentar de novo` · `Pular por agora`

  - página deu erro → ask them to paste what it said (the only free text you need).
  - outra conta → sign out of that service in the browser, then repeat 2A once.
  - tentar de novo → call `authenticate` again and resend the link, once.
  - pular → record `pending` and continue; the SessionStart hook nudges later.

Never loop more than twice on the same service; then record `pending`, say so
plainly, and continue.

### 2B. Connector not in the session at all

The account has not added it yet. Inside this window:

> 1. Clique no botão **+** ao lado da caixa de mensagem e escolha **Connectors**.
> 2. Procure **Supabase** no cartão e clique em **Usar**. Se ele não estiver ali,
>    clique em **Explorar mais de 650 conectores**, procure Supabase e adicione.
> 3. Volte aqui e me diga "pronto".

Then look again: with the connector added, the `authenticate` tool shows up and you
continue at **2A**. If the tools still do not appear, ask them to open a **new
conversation** and type `/alison-plugin:comecar` — connectors load when a session
starts.

### 2C. Last resort only

If, and only if, 2B did not work twice: claude.ai → Configurações → Conectores →
**Browse connectors** → the service → **Connect**, then a new conversation here.
Never offer this earlier: the person came to use the app, not the website.

### 2D. GitHub — the credential on this machine

**If the step 0 probe said `connected`, GitHub is done.** Say one line — "GitHub já
está ligado nesta máquina ✓", with the account name when `gh` gave it — and go to
step 3. Do **not** mention claude.ai/code, do not open anything, do not ask. Sending
someone to re-do a connection they already made is the worst thing this skill can
do: the page they land on no longer has the button you described.

Otherwise, one route, chosen by what exists:

- **`gh` is installed** → run `gh auth login --web --git-protocol https` and tell
  them: "Vai aparecer um código aqui e uma janela do navegador. Confirme o código
  e entre na sua conta."
- **`gh` is not installed** (the common case) → GitHub Desktop, the official app:
  > 1. Baixe o **GitHub Desktop** em https://desktop.github.com e instale.
  > 2. Abra o app, clique em **Sign in to GitHub.com** e entre na sua conta no
  >    navegador.
  > 3. Volte aqui e me diga "pronto".

Then run the step 0 probe again.

- Prints → "GitHub ligado ✓".
- Still nothing → do not loop. Say plainly: "Ficou pendente. Na primeira vez que o
  Claude enviar um arquivo para o GitHub, vai abrir uma janela do navegador pedindo
  o login — é normal, e depois disso fica guardado." Record `pending` and continue.

**The cloud half is optional and is never a step here.** Only if the person asks to
work on their repositories without depending on this computer, mention it once, and
with the conditional that keeps it from being a dead end: "Abra claude.ai/code; **se
aparecer** um botão **Connect GitHub**, autorize. Se já aparecer a lista dos seus
repositórios, não há nada a fazer."

## 3. House rules and protections

### 3a. Global CLAUDE.md

Template: `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.global.md`. It only tells Claude
to speak plainly, confirm before changing anything on those services, and never
handle keys — safe for anyone.

- `~/.claude/CLAUDE.md` **does not exist** → copy the template. No question.
- It **exists** → back it up
  (`cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak-$(date +%Y%m%d-%H%M%S)`), then
  **ASK #3**, header `Regras`:
  > "Você já tem um arquivo de regras para o Claude. O que fazer com ele?"
  > `Manter o meu e adicionar as regras do plugin no final` (Recommended) ·
  > `Substituir pelo do plugin` · `Deixar como está`

  When appending, separate with `\n\n<!-- alison-plugin: regras abaixo -->\n\n`.

### 3b. Machine-wide git ignore list (no question)

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-git-protections.sh"
```

Prints `gitignore_global=created|merged|skipped …`. Say it in one line, in the
person's words: "Arquivos de chave e senha (.env e parecidos) e arquivos gerados
automaticamente (node_modules, builds, caches, logs) agora são ignorados pelo Git em
qualquer pasta deste computador — só o que você escreveu sobe." When `skipped`, say the protection
enters automatically once Git is installed, and move on. On **Windows** that means
Git for Windows (https://git-scm.com/download/win) — the Claude Code app itself
needs it for anything in this skill that runs a command; say it once, plainly. The second protection
needs nothing installed: the plugin already checks everything that goes to GitHub
(`github-guard`) and stops or asks before anything sensitive leaves.

## 4. Record (so the hook stops nudging)

Write `~/.claude/alison/config.json` (Windows: `%USERPROFILE%\.claude\alison\config.json`)
with the **Write** tool — no script, no python — from the probe results:

```json
{
  "connections": { "github": "connected", "supabase": "needs_auth", "vercel": "connected", "firecrawl": "connected" },
  "github_desktop": "pending",
  "setup_version": 3,
  "updated_at": "YYYY-MM-DD"
}
```

Values are exactly `connected`, `needs_auth`, `failed` or `pending`. Create the
folder if needed (`mkdir -p ~/.claude/alison`). The SessionStart hook greps this
file for `"<service>": "connected"`, nothing else.

## 5. Prove it works, then stop

For each `connected` service, make **one read-only call** with its tools and show
the answer in one line each — this is the moment the person sees it is real:

- Firecrawl: one small `firecrawl_search` on something they care about → "Procurei
  na web e achei: …". The only step 5 call that spends free-tier credit; do it once.
- GitHub: `gh repo list --limit 3` when `gh` is authenticated → "Sua conta X tem
  estes repositórios: …". With only a stored credential there is nothing free to
  list; say the machine is ready to send files to GitHub and move on.
- Supabase: the tool that lists projects (or organizations) → "Sua organização Y
  tem N projetos".
- Vercel: the tool that lists projects → "Você tem N projetos na Vercel".

Before the first call, warn in one line that a permission box will appear and
that answering **Yes** is expected — it is Claude Code asking, not the service.
Never create, change or delete anything in this step. If a call fails, say so in
one plain line and move on — the connection status from step 2 still stands.

Close with at most nine lines: what is connected, what is pending (and that
`/alison-plugin:comecar` finishes it later), what happened to the rules
file, one line on the protections ("nada de chave ou senha sobe para o GitHub sem
você ver — e se for planilha ou lista de pessoas, ele pergunta antes"), and four
things to try now, one per service, e.g.:

> - "Quais foram as últimas mudanças no meu repositório X?"
> - "Que tabelas existem no meu projeto Supabase?"
> - "Meu último deploy na Vercel deu certo?"
> - "Pesquise na web como os concorrentes cobram por isso e resuma"

No **ASK** here. Ending the turn is the invitation.
