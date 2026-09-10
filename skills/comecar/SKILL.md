---
name: comecar
description: Guided, plain-language onboarding that connects Claude Code to GitHub, Supabase and Vercel through browser login (OAuth) and verifies each connection by using it (one read-only call) instead of asking — works in the desktop app, where the claude CLI is not on PATH. Use when the SessionStart hook says the connections are not configured, on the first session after installing alison-plugin, or when the user says "começar", "conectar", "configurar", "ligar o GitHub / Supabase / Vercel", "não está conectado", "o que eu consigo fazer aqui". Idempotent — re-run any time; it only touches what is still pending.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# comecar — connect GitHub, Supabase and Vercel, one at a time

The person in front of you does **not** program. They will never read a config
file, and every question you ask costs them confidence. Rules that override any
default behaviour while this skill runs:

- **Portuguese, plain words.** Never say MCP, OAuth, token, CLI, terminal, JSON or
  hook unprompted. Say "conexão", "login no navegador", "esta janela".
- **Questions happen at exactly four moments** (marked `ASK` below). Everything else
  you check yourself (probe a tool, run a script) and simply report. Never ask
  "deu certo?" — probe.
- **One service per message.** Finish GitHub before mentioning Supabase.
- **Never ask for, accept or store a password or key.** The connection is a browser
  login. If the user pastes a key, tell them kindly not to, and do not repeat it.
- **Never run `/mcp` yourself** — you cannot; the user types it. Give the exact
  keystrokes. They work the same in the terminal and in the desktop app.
- **Verify by using, not by CLI.** A connection is proven when one of its tools
  answers a read-only call. `claude mcp list` is a bonus when available.

Names as they appear in this session: `plugin:alison-plugin:github`,
`plugin:alison-plugin:supabase`, `plugin:alison-plugin:vercel`.

## 0. Ground truth, silently

Order on a **first run** (no `config.json`): send the welcome of step 1 *before*
the first probe — a probe can pop the permission box, and the person must have
read that answering **Yes** is expected. On later runs, probe straight away.

The person may be in the **desktop app** (Mac or Windows), where the `claude`
command is often not on the shell's PATH. So the source of truth is not a CLI: it
is whether each service's tools **answer**. Probe each one with a read-only call:

| service | probe (use whichever of these tools exists in the session) | result |
|---|---|---|
| GitHub | `get_me` / the tool that returns the authenticated user | `connected` |
| Supabase | `list_organizations` / `list_projects` | `connected` |
| Vercel | `list_teams` / `list_projects` | `connected` |

- Tool **not present** in the session, or the call fails with anything about
  authentication / 401 / unauthorized → `needs_auth`.
- Tools present under a **claude.ai connector** name (e.g. "claude.ai Supabase")
  also count as `connected` — the person already logged in through claude.ai;
  do not make them log in twice.
- Any other error → `failed`; keep the message for ASK #2.

Optional accelerator, only when it works:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-connections.sh"   # github=… supabase=… vercel=…
```

If it prints `error=claude CLI not on PATH` or every line says `missing`, ignore it
silently and trust the probes — never tell the person to "restart" because of it.

Also read `~/.claude/alison/config.json` (`%USERPROFILE%\.claude\alison\config.json`
on Windows) if it exists, and note whether `~/.claude/CLAUDE.md` exists.

- All three `connected` → jump to **step 5**. Nothing to ask.
- The plugin's own servers absent from `/mcp` entirely (no `plugin:alison-plugin:*`
  and no probe tool at all) → ask the person to type `/reload-plugins`, then close
  and reopen this session. Stop.

## 1. Welcome (first run only — no `config.json`)

One message, five lines max: we will connect three services by logging in on the
browser, about five minutes, nothing to install, nothing to copy; a small
permission box may appear when Claude checks a connection — answering **Yes** is
expected. Then:

**ASK #1** — AskUserQuestion, `multiSelect: true`, header `Contas`:
> "Em quais destes você já tem conta?" options: `GitHub` · `Supabase` · `Vercel`
> · `Nenhuma ainda`.

For every service without an account, give the sign-up link and one tip, then wait
for "pronto" before continuing:

| service | link | tip |
|---|---|---|
| GitHub | https://github.com/signup | create this one first |
| Supabase | https://supabase.com/dashboard/sign-up | click **Continue with GitHub** — no new password |
| Vercel | https://vercel.com/signup | click **Continue with GitHub** — no new password |

If the user already has all three, skip the table entirely.

## 2. Connect, in order: GitHub → Supabase → Vercel

Skip any service already `connected`. For the current one, send **exactly** this
(adapt the name and the provider line):

> Vamos conectar o **GitHub**.
> 1. Digite `/mcp` e aperte Enter.
> 2. Na lista, use as setas até `plugin:alison-plugin:github` e aperte Enter.
> 3. Escolha **Authenticate**. O navegador vai abrir.
> 4. Entre na sua conta e clique em **Authorize**.
> 5. Volte para esta janela e me diga "pronto".

Provider line for step 4:
- Supabase: "Ele pergunta qual organização autorizar — escolha a sua (normalmente só existe uma)."
- Vercel: "Se ele perguntar qual time (scope), escolha o seu nome."

When the user comes back, **do not ask anything** — probe the service again
(step 0 table). If the tool still is not listed right after the login, the
session may not have refreshed its tool list: say "vou atualizar a lista" and try
once more; if still absent, ask for `/reload-plugins` once before ASK #2.

- Probe answers → one line: "GitHub conectado ✓". Move to the next service.
- Still `needs_auth` or `failed` → **ASK #2**, header with the service name:
  > "A conexão com o GitHub ainda não apareceu. O que aconteceu?"
  > `O navegador não abriu` · `Deu erro na tela de autorização` ·
  > `Fechei antes de autorizar — quero tentar de novo` · `Pular por agora`

  - navegador não abriu → in `/mcp` → Authenticate, a link is printed; copy it
    into any browser. Probe again afterwards.
  - erro na tela → ask them to paste what the screen said (that is the only free
    text you need); the common causes are wrong account and, for GitHub, an
    organisation that blocks third-party apps — say which one it looks like.
  - tentar de novo → repeat the five steps once.
  - pular → record `pending` and continue; the SessionStart hook will nudge later.

Never loop more than twice on the same service; after that, record `pending`,
say so plainly, and continue.

## 3. House rules and protections

### 3a. Global CLAUDE.md

Template: `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.global.md`. It only tells Claude
to speak plainly, confirm before changing anything on the three services, and never
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
  "connections": { "github": "connected", "supabase": "needs_auth", "vercel": "connected" },
  "setup_version": 2,
  "updated_at": "YYYY-MM-DD"
}
```

Values are exactly `connected`, `needs_auth`, `failed` or `pending`. Create the
folder if needed (`mkdir -p ~/.claude/alison`). The SessionStart hook greps this
file for `"<service>": "connected"`, nothing else.

## 5. Prove it works, then stop

For each `connected` service, make **one read-only call** with its tools and show
the answer in one line each — this is the moment the person sees it is real:

- GitHub: the tool that lists the authenticated user's repositories → "Vi N
  repositórios, o mais recente é X".
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
você ver — e se for planilha ou lista de pessoas, ele pergunta antes"), and three
things to try now, one per service, e.g.:

> - "Quais foram as últimas mudanças no meu repositório X?"
> - "Que tabelas existem no meu projeto Supabase?"
> - "Meu último deploy na Vercel deu certo?"

No **ASK** here. Ending the turn is the invitation.
