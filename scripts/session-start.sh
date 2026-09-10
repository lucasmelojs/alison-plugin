#!/usr/bin/env bash
# apresentacao-plugin SessionStart — one cheap line of orientation, never blocks.
# Does NOT call `claude mcp list` (health checks take seconds; the hook has 5s).
# The skill writes ~/.claude/apresentacao/config.json when the three connections
# were verified; until then, every session gets the nudge. Exit 0 always.
set -uo pipefail

CONFIG="$HOME/.claude/apresentacao/config.json"

if [ ! -f "$CONFIG" ]; then
  echo "apresentacao-plugin: as conexões com GitHub, Supabase e Vercel ainda não foram configuradas — digite /apresentacao-plugin:comecar para começar."
  exit 0
fi

pending="$(python3 -c 'import json,sys
cfg=json.load(open(sys.argv[1]))
c=cfg.get("connections",{})
print(",".join(s for s in ("github","supabase","vercel") if c.get(s)!="connected"))' "$CONFIG" 2>/dev/null || true)"

[ -n "$pending" ] && echo "apresentacao-plugin: conexão pendente ($pending) — digite /apresentacao-plugin:comecar para terminar."
exit 0
