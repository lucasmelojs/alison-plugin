#!/usr/bin/env bash
# alison-plugin SessionStart — one cheap line of orientation, never blocks.
# Does NOT call `claude mcp list` (health checks take seconds; the hook has 5s)
# and does NOT need python3 (absent on a stock Windows). The skill writes
# ~/.claude/alison/config.json once the four connections were verified; until
# then every session gets the nudge. Exit 0 always.
set -uo pipefail

CONFIG="$HOME/.claude/alison/config.json"

if [ ! -f "$CONFIG" ]; then
  echo "alison-plugin: as conexões com GitHub, Supabase, Vercel e Firecrawl ainda não foram configuradas — digite /alison-plugin:comecar para começar."
  exit 0
fi

pending=""
for s in github supabase vercel firecrawl; do
  grep -Eq "\"$s\"[[:space:]]*:[[:space:]]*\"connected\"" "$CONFIG" || pending="${pending:+$pending,}$s"
done

[ -n "$pending" ] && echo "alison-plugin: conexão pendente ($pending) — digite /alison-plugin:comecar para terminar."
exit 0
