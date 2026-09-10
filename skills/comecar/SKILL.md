---
name: comecar
description: Guided, plain-language onboarding that leads a non-programmer through the NATIVE integrations of the Claude Code desktop app — claude.ai Connectors for Supabase and Vercel, the Claude GitHub App (claude.ai/code) and GitHub Desktop for GitHub — and verifies each one by using it instead of asking. No plugin-shipped servers, no keys, no terminal. Use when the SessionStart hook says the connections are not configured, on the first session after installing alison-plugin, or when the user says "começar", "conectar", "configurar", "ligar o GitHub / Supabase / Vercel", "não está conectado", "o que eu consigo fazer aqui". Idempotent — re-run any time; it only touches what is still pending.
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
- **Never click for them.** The **+** button, **Connectors**, claude.ai pages: the
  person does it; you give exact labels, one step per line.
- **Verify by using.** A connection is proven when one of its tools answers a
  read-only call. There is no CLI in this surface; do not look for one.

This plugin ships **no servers**. Everything comes from the app's own integrations:
Supabase and Vercel are claude.ai **Connectors** (they show up as `claude.ai Supabase`
and `claude.ai Vercel`); GitHub is the **Claude GitHub App** (claude.ai/code) plus, for
folders on this computer, **GitHub Desktop**. GitHub has no connector and its remote
server needs a pasted token, which this audience must never do (AD-007).

## 0. Ground truth, silently

Order on a **first run** (no `config.json`): send the welcome of step 1 *before*
the first probe — a probe can pop the permission box, and the person must have
read that answering **Yes** is expected. On later runs, probe straight away.

The person is in the **Claude Code desktop app** (Mac or Windows). The source of
truth is whether each service's tools **answer**. Probe each one with a read-only
call:

| service | how it is proven | result |
|---|---|---|
| Supabase | a `claude.ai Supabase` tool answers `list_organizations` / `list_projects` | `connected` |
| Vercel | a `claude.ai Vercel` tool answers `list_teams` / `list_projects` | `connected` |
| GitHub | no tool to call. `connected` = the person confirmed their repositories are listed on claude.ai/code (ASK #1b) **or** `gh auth status` succeeds in Bash when `gh` exists | `connected` |

- Connector tool **not present**, or the call fails with anything about
  authentication / 401 / unauthorized / "session token rejected" → `needs_auth`.
- Any other error → `failed`; keep the message for ASK #2.
- The plugin has no servers of its own; do not look for any.

Also read `~/.claude/alison/config.json` (`%USERPROFILE%\.claude\alison\config.json`
on Windows) if it exists, and note whether `~/.claude/CLAUDE.md` exists.

- All three `connected` → jump to **step 5**. Nothing to ask.
- `/mcp` empty of any `claude.ai …` entry although the person says they connected →
  the session predates the connection; ask them to open a **new conversation** and
  type `/alison-plugin:comecar` again. Stop.

## 1. Welcome (first run only — no `config.json`)

One message, five lines max: we will switch on three connections that already live in the
app, by logging in on the browser, about five minutes, nothing to copy; a small
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

## 2. Connect, in order: Supabase → Vercel → GitHub

Skip any service already `connected`. Connectors first: they are the two clicks
the person can see working immediately. GitHub last, because it has two halves.

### Supabase and Vercel — Connectors (same steps, swap the name)

> Vamos conectar o **Supabase**.
> 1. Clique no botão **+** ao lado da caixa de mensagem e escolha **Connectors**.
> 2. Procure **Supabase** e clique em **Connect**. Se não aparecer na lista, clique
>    em **Manage connectors** — abre o claude.ai; lá vá em Configurações →
>    Conectores → **Browse connectors** → Supabase → **Connect**.
> 3. O navegador abre. Entre na sua conta e clique em **Authorize**.
> 4. Volte para esta janela e me diga "pronto".

Provider line for step 3:
- Supabase: "Ele pergunta qual organização autorizar — escolha a sua (normalmente só existe uma)."
- Vercel: "Se ele perguntar qual time (scope), escolha o seu nome."

When the user comes back, **do not ask anything** — probe (step 0 table). If the
connector is not in the session yet, say "vou atualizar a lista" and look once
more; if still absent, ask for a **new conversation** (connectors load when a
session starts) before ASK #2.

- Probe answers → one line: "Supabase conectado ✓". Next service.
- Still `needs_auth` or `failed` → **ASK #2**, header with the service name:
  > "A conexão com o Supabase ainda não apareceu. O que aconteceu?"
  > `O navegador não abriu` · `Deu erro na tela de autorização` ·
  > `Fechei antes de autorizar — quero tentar de novo` · `Pular por agora`

  - navegador não abriu → claude.ai → Configurações → Conectores → o serviço →
    **Connect**, directly in the browser. Probe again afterwards.
  - erro na tela → ask them to paste what the screen said (the only free text you
    need); the usual cause is the wrong account (a different Google/GitHub login).
  - tentar de novo → repeat the four steps once.
  - pular → record `pending` and continue; the SessionStart hook will nudge later.

Never loop more than twice on the same service; after that, record `pending`,
say so plainly, and continue.

### GitHub — the Claude GitHub App, then GitHub Desktop

There is no GitHub connector, and the GitHub server needs a pasted token — never.
The native path has two halves; say in one line that the first lets Claude work on
their repositories in the cloud, the second lets Claude send files from this
computer.

> Vamos conectar o **GitHub**.
> 1. Abra https://claude.ai/code no navegador (mesma conta que você usa neste app).
> 2. Clique em **Connect GitHub** e autorize o **Claude** (escolha sua conta; pode
>    marcar todos os repositórios).
> 3. Quando a lista de repositórios aparecer, volte aqui e me diga "pronto".

**ASK #1b** — the only connection you cannot probe, header `GitHub`:
> "Na página do claude.ai/code, seus repositórios apareceram na lista?"
> `Sim, apareceram` · `Só aparece o botão de entrar` · `Deu erro`

- Sim → `connected`. Then the second half, no question: if `gh` exists in Bash and
  `gh auth status` fails, run `gh auth login --web --git-protocol https` and tell
  them a browser window will ask them to confirm a code. If `gh` does not exist,
  tell them once: "Para o Claude enviar arquivos desta máquina para o GitHub,
  instale o **GitHub Desktop** (https://desktop.github.com) e entre na sua conta lá
  — ele configura o acesso; nada para copiar." Record `"github_desktop": "pending"`
  in config.json; do not wait for it.
- Só o botão → they are not signed in to GitHub in that browser; sign in there and
  repeat step 2. One retry, then `pending`.
- Deu erro → paste what it said; organisations that block third-party apps are
  the usual cause.

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

- GitHub: `gh api user --jq .login` and `gh repo list --limit 3` when `gh` is
  authenticated → "Sua conta X tem estes repositórios: …"; otherwise say the
  repositories are the ones they saw on claude.ai/code and move on.
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
