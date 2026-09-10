#!/usr/bin/env bash
# Exercises github-guard.sh and install-git-protections.sh against fabricated hook
# payloads in a throwaway git repo and HOME. Run: scripts/test-github-guard.sh
# Exit 1 on the first failed expectation; prints PASS/FAIL per case.
set -o pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/github-guard.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"
git config --global user.email t@t; git config --global user.name t; git config --global init.defaultBranch main
R="$T/repo"; mkdir -p "$R"; git -C "$R" init -q

fail=0
payload_bash() { printf '{"session_id":"s","hook_event_name":"PreToolUse","cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$R" "$1"; }
run() { # $1 name, $2 expect (block|ask|silent), stdin payload
  local name="$1" expect="$2" out err code
  out="$("$GUARD" 2>"$T/err")"; code=$?; err="$(cat "$T/err")"
  local got=silent
  [ "$code" = 2 ] && got=block
  printf '%s' "$out" | grep -q '"permissionDecision":"ask"' && got=ask
  if [ "$got" = "$expect" ]; then echo "PASS  $name"; else echo "FAIL  $name — expected $expect, got $got (exit $code)"; echo "$out$err" | sed 's/^/      /'; fail=1; fi
}
cd "$R"

# A: staged .env → block by name
echo "X=1" > .env; git add -f .env
payload_bash 'git commit -m init' | run "A staged .env blocks" block
git rm -q --cached .env; rm .env

# B: staged note with Stripe live key → block by content
echo "usar sk_live_abcdefghijklmnop123 no checkout" > notes.md; git add notes.md
payload_bash 'git commit -m notes' | run "B sk_live in staged file blocks" block
git rm -q --cached notes.md; rm notes.md

# D: clean README → silent, then commit it for later cases
echo "# Projeto" > README.md; git add README.md
payload_bash 'git commit -m readme' | run "D clean staged file is silent" silent
git commit -qm readme

# C: commit -a with an unstaged CSV of CPFs → ask
printf 'nome,cpf\nAna,123.456.789-09\nBia,987.654.321-00\n' > clientes.csv
payload_bash 'git commit -am dados' | run "C commit -a with CSV of CPFs asks" ask
rm clientes.csv

# E: unrelated git command → silent
payload_bash 'git status' | run "E git status is silent" silent

# F: first push with a .pem in HEAD → block by name
mkdir -p config; echo "not really" > config/server.pem; git add -f config/server.pem; git commit -qm pem
payload_bash 'git push -u origin main' | run "F push with .pem in history blocks" block
git rm -q --cached config/server.pem; git commit -qm rm-pem; rm -rf config

# K: false positives → silent
printf 'token = generate_token_for_user()\npassword: string\nPASSWORD_MIN_LENGTH = 8\n' > app.ts; git add app.ts
payload_bash 'git commit -m code' | run "K identifiers that look like secrets stay silent" silent
git rm -q --cached app.ts; rm app.ts

# L: quoted generic api key → block
printf 'const cfg = { api_key: "abcd1234efgh5678ijkl" }\n' > cfg.js; git add cfg.js
payload_bash 'git commit -m cfg' | run "L quoted api_key value blocks" block
git rm -q --cached cfg.js; rm cfg.js

# L2: env-style unquoted secret → block
printf 'SUPABASE_URL=https://x.supabase.co\nSUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc\n' > env.txt; git add env.txt
payload_bash 'git commit -m env' | run "L2 service role key blocks" block
git rm -q --cached env.txt; rm env.txt

# M: contact list (>=5 emails) → ask
printf 'a@x.com\nb@x.com\nc@x.com\nd@x.com\ne@x.com\nf@x.com\n' > contatos.txt; git add contatos.txt
payload_bash 'git commit -m contatos' | run "M six e-mails ask" ask
git rm -q --cached contatos.txt; rm contatos.txt

# Q: node_modules forced into the index → ask (generated noise)
mkdir -p node_modules/left-pad; echo "module.exports=1" > node_modules/left-pad/index.js; git add -f node_modules/left-pad/index.js
payload_bash 'git commit -m deps' | run "Q node_modules staged asks" ask
git rm -rq --cached node_modules; rm -rf node_modules

# R: 12 MB file staged → ask (large), no content read
head -c 12000000 /dev/zero | tr '\0' 'a' > video.bin; git add video.bin
payload_bash 'git commit -m big' | run "R 12 MB file asks" ask
git rm -q --cached video.bin; rm video.bin

mcp() { printf '{"session_id":"s","hook_event_name":"PreToolUse","cwd":"%s","tool_name":"mcp__claude_ai_GitHub__%s","tool_input":%s}' "$R" "$1" "$2"; }
mcp push_files '{"owner":"o","repo":"r","branch":"main","files":[{"path":"src/a.ts","content":"const t = \"ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\"\n"}],"message":"m"}' | run "G MCP push_files with ghp_ token blocks" block
mcp create_or_update_file '{"owner":"o","repo":"r","path":".env","content":"A=1","message":"m","branch":"main"}' | run "H MCP writing .env blocks by name" block
mcp create_or_update_file '{"owner":"o","repo":"r","path":"dados/lista.xlsx","content":"UEsDBBQ=","message":"m","branch":"main"}' | run "I MCP writing .xlsx asks" ask
mcp create_or_update_file '{"owner":"o","repo":"r","path":"docs/a.md","content":"api_key = \"abcd1234efgh5678ijkl\"","message":"m","branch":"main"}' | run "J MCP escaped-quote api_key blocks" block
mcp list_repositories '{"owner":"o"}' | run "N MCP read-only tool is silent" silent
mcp create_or_update_file '{"owner":"o","repo":"r","path":".env.example","content":"API_KEY=\n","message":"m","branch":"main"}' | run "O .env.example is allowed" silent

# install-git-protections: create, then merge (0 added), then merge into a custom file
INST="$HERE/install-git-protections.sh"
o1="$("$INST")"; echo "$o1" | grep -q 'gitignore_global=created' && echo "PASS  P1 excludes file created ($o1)" || { echo "FAIL  P1 $o1"; fail=1; }
o2="$("$INST")"; echo "$o2" | grep -q 'gitignore_global=merged .* added=0' && echo "PASS  P2 second run adds nothing" || { echo "FAIL  P2 $o2"; fail=1; }
printf 'node_modules/\n' > "$HOME/myignore"; git config --global core.excludesFile "$HOME/myignore"
o3="$("$INST")"; echo "$o3" | grep -Eq 'gitignore_global=merged .* added=[1-9]' && grep -q '^node_modules/$' "$HOME/myignore" && grep -q '^\.env$' "$HOME/myignore" && echo "PASS  P3 existing list kept and extended ($o3)" || { echo "FAIL  P3 $o3"; fail=1; }
# the global list really hides .env from git add .
echo "S=1" > "$R/.env"; git -C "$R" add . ; git -C "$R" diff --cached --name-only | grep -q '^\.env$' && { echo "FAIL  P4 .env still added"; fail=1; } || echo "PASS  P4 global ignore hides .env from git add ."

# P5: the global list also hides node_modules, .next and logs from git add .
mkdir -p "$R/node_modules/x" "$R/.next"; echo 1 > "$R/node_modules/x/i.js"; echo 1 > "$R/.next/b"; echo 1 > "$R/app.log"; echo 1 > "$R/src.js"
git -C "$R" add . ; staged="$(git -C "$R" diff --cached --name-only)"
if echo "$staged" | grep -Eq 'node_modules|\.next|app\.log'; then echo "FAIL  P5 generated files still added: $staged"; fail=1; else echo "$staged" | grep -q '^src.js$' && echo "PASS  P5 global ignore hides node_modules/.next/logs, keeps source" || { echo "FAIL  P5 source not staged"; fail=1; }; fi

exit $fail
