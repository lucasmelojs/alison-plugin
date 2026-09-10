#!/usr/bin/env bash
# apresentacao-plugin PreToolUse guard — nothing sensitive reaches GitHub unnoticed.
#
# Reads the hook JSON on stdin (tool_name, tool_input, cwd). Three outcomes:
#   silence            nothing found                      exit 0
#   BLOCK              secrets, keys, credential files    exit 2, reason on stderr
#   CONFIRM            personal data, spreadsheets, dumps JSON permissionDecision=ask
# Covers two roads to GitHub: Bash commands that `git commit` / `git push`, and the
# GitHub MCP tools that write content (create_or_update_file, push_files, gists…).
# Patterns live in ./patterns/*.txt (grep -E, case-insensitive) so Lucas edits a
# list, not this script. Deliberately no `set -u`: macOS ships bash 3.2, where
# empty arrays trip it. Never depends on python3 for the MCP road.
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$HERE/patterns"
INPUT="$(cat)"
MAX_FILES=500
MAX_BYTES=10000000   # above this a file is a CONFIRM by itself and is not read
BLOCKS=()
CONFIRMS=()

python_usable() {
  command -v python3 >/dev/null 2>&1 || return 1
  [ "$(uname)" != "Darwin" ] || xcode-select -p >/dev/null 2>&1
}

json_field() { # $1 = dotted path, e.g. tool_input.command
  if python_usable; then
    printf '%s' "$INPUT" | python3 -c 'import json,sys
d=json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d=d.get(k,{}) if isinstance(d,dict) else {}
print(d if isinstance(d,str) else "")' "$1" 2>/dev/null
    return
  fi
  local key="${1##*.}"
  printf '%s' "$INPUT" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

check_name() { # $1 = path as it will exist in the repo
  local n="$1"
  if printf '%s\n' "$n" | grep -Eiq -f "$P/filenames-block.txt" \
     && ! printf '%s\n' "$n" | grep -Eiq -f "$P/filenames-allow.txt"; then
    BLOCKS+=("$n — arquivo de credenciais (pelo nome)")
    return
  fi
  if printf '%s\n' "$n" | grep -Eiq -f "$P/filenames-confirm.txt"; then
    CONFIRMS+=("$n — planilha ou banco de dados: costuma ter dados de pessoas")
    return
  fi
  printf '%s\n' "$n" | grep -Eiq -f "$P/filenames-noise.txt" \
    && CONFIRMS+=("$n — gerado automaticamente ou temporário: não precisa ir para o GitHub (node_modules, build, cache, log)")
}

check_content() { # $1 = label; content on stdin
  local label="$1" tmp hit emails
  tmp="$(mktemp)"; cat > "$tmp"
  local bytes; bytes="$(wc -c < "$tmp" | tr -d ' ')"
  if [ "$bytes" -gt "$MAX_BYTES" ]; then
    CONFIRMS+=("$label — arquivo grande ($((bytes / 1000000)) MB): GitHub não é lugar de vídeo, base de dados ou pacote")
    rm -f "$tmp"; return
  fi
  hit="$(grep -EIio -m1 -f "$P/content-block.txt" "$tmp" 2>/dev/null | head -1)"
  if [ -n "$hit" ]; then
    BLOCKS+=("$label — parece conter uma chave ou senha (começa com ${hit:0:10}…)")
    rm -f "$tmp"; return
  fi
  hit="$(grep -EIo -m1 -f "$P/content-confirm.txt" "$tmp" 2>/dev/null | head -1 | sed 's/^[^0-9A-Za-z]*//')"
  [ -n "$hit" ] && CONFIRMS+=("$label — parece conter CPF, cartão ou token (${hit:0:6}…)")
  emails="$(grep -EIo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$tmp" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
  [ "${emails:-0}" -ge 5 ] && CONFIRMS+=("$label — $emails e-mails diferentes: parece lista de contatos")
  rm -f "$tmp"
}

# --- road 1: git commit / git push through Bash --------------------------------
scan_git() {
  local cmd="$1" cwd="$2" root is_push=0 adds_all=0 n=0 list
  [ -n "$cwd" ] && [ -d "$cwd" ] && cd "$cwd" 2>/dev/null
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  cd "$root" || return 0
  printf '%s' "$cmd" | grep -Eq 'git[^|;&]*[[:space:]]push([[:space:]]|$)' && is_push=1
  printf '%s' "$cmd" | grep -Eq 'git[^|;&]*[[:space:]]add([[:space:]]|$)|commit[^|;&]*[[:space:]]-[A-Za-z]*a|--all' && adds_all=1

  # lines "source<TAB>path"; source tells where the content lives
  list="$( {
    git diff --cached --name-only --diff-filter=ACMR | sed 's/^/staged\t/'
    if [ "$adds_all" = 1 ]; then
      git diff --name-only --diff-filter=ACMR | sed 's/^/worktree\t/'
      git ls-files --others --exclude-standard | sed 's/^/worktree\t/'
    fi
    if [ "$is_push" = 1 ]; then
      if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        git diff --name-only --diff-filter=ACMR '@{u}..HEAD' | sed 's/^/head\t/'
      else
        git ls-tree -r --name-only HEAD 2>/dev/null | sed 's/^/head\t/'
      fi
    fi
  } | awk -F'\t' '!seen[$2]++' )"

  while IFS=$'\t' read -r src path; do
    [ -z "$path" ] && continue
    n=$((n + 1))
    check_name "$path"
    [ "$n" -gt "$MAX_FILES" ] && continue
    case "$src" in
      # process substitution, not a pipe: a pipe would run check_content in a
      # subshell and drop every finding it appends to BLOCKS/CONFIRMS.
      staged)   check_content "$path" < <(git show ":$path" 2>/dev/null) ;;
      head)     check_content "$path" < <(git show "HEAD:$path" 2>/dev/null) ;;
      worktree) [ -f "$path" ] && check_content "$path" < "$path" ;;
    esac
  done <<< "$list"
  [ "$n" -gt "$MAX_FILES" ] && CONFIRMS+=("$n arquivos de uma vez — só os primeiros $MAX_FILES foram lidos por dentro")
  return 0
}

# --- road 2: GitHub MCP tools that write ------------------------------------------
scan_mcp() {
  # Content and paths travel inside JSON strings; token patterns survive escaping,
  # so the raw payload is scanned as one document (no JSON parser needed).
  check_content "conteúdo enviado pela conexão GitHub" <<< "$INPUT"
  while IFS= read -r p; do
    [ -n "$p" ] && check_name "$p"
  done < <(printf '%s' "$INPUT" | grep -Eo '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/^"path"[[:space:]]*:[[:space:]]*"//; s/"$//')
  return 0
}

tool="$(json_field tool_name)"
case "$tool" in
  Bash)
    cmd="$(json_field tool_input.command)"
    [ -z "$cmd" ] && cmd="$INPUT"
    printf '%s' "$cmd" | grep -Eq 'git[^|;&]*[[:space:]](commit|push)([[:space:]]|$)' || exit 0
    scan_git "$cmd" "$(json_field cwd)"
    ;;
  mcp__*github__*)
    scan_mcp
    ;;
  *) exit 0 ;;
esac

if [ "${#BLOCKS[@]}" -gt 0 ]; then
  {
    echo "BLOQUEADO — isto não pode ir para o GitHub:"
    for b in "${BLOCKS[@]}"; do echo "  • $b"; done
    echo "O que fazer: tire o arquivo ou o valor do envio (chaves ficam no .env, que já é ignorado) e peça de novo."
    echo "Se essa chave já foi enviada alguma vez, troque-a no serviço que a emitiu — apagar do repositório não basta."
    echo "Nunca contorne com --no-verify, renomeando o arquivo ou colando o valor em outro lugar."
  } >&2
  exit 2
fi

if [ "${#CONFIRMS[@]}" -gt 0 ]; then
  reason="Isto vai para o GitHub e parece desnecessário ou conter dados de pessoas:"
  for c in "${CONFIRMS[@]}"; do reason="$reason"$'\n'"  • $c"; done
  reason="$reason"$'\n'"Confirme só se tem certeza de que isso precisa estar no repositório e pode ser visto por quem o acessa."
  # minimal JSON string escaping: backslash, quote, newline, tab
  esc="$(printf '%s' "$reason" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {gsub(/\t/,"\\t"); print}' | sed 's/\\n$//')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$esc"
fi
exit 0
