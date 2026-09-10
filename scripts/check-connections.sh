#!/usr/bin/env bash
# apresentacao-plugin — reports the auth state of the three bundled MCP servers.
# Output, one per line, stable for the skill to parse:
#   github=connected | needs_auth | failed | missing
# Reads `claude mcp list` (health-checked, uses the credentials stored by /mcp).
# Exit 0 when all three are connected, 1 otherwise. Never blocks longer than the
# `claude mcp list` health check itself.
set -uo pipefail

PLUGIN_NAME="${PLUGIN_NAME:-apresentacao-plugin}"
# SERVERS is overridable only so the parser can be tested against another
# installed plugin (e.g. PLUGIN_NAME=stripe SERVERS="stripe").
read -r -a SERVERS <<< "${SERVERS:-github supabase vercel}"

if ! command -v claude >/dev/null 2>&1; then
  for s in "${SERVERS[@]}"; do echo "$s=missing"; done
  echo "error=claude CLI not on PATH"
  exit 1
fi

listing="$(claude mcp list 2>/dev/null || true)"

all_ok=0
for s in "${SERVERS[@]}"; do
  line="$(printf '%s\n' "$listing" | grep -F "plugin:${PLUGIN_NAME}:${s}:" | head -1)"
  if [ -z "$line" ]; then
    echo "$s=missing"; all_ok=1; continue
  fi
  case "$line" in
    *"Connected"*)           echo "$s=connected" ;;
    *"Needs authentication"*) echo "$s=needs_auth"; all_ok=1 ;;
    *)                        echo "$s=failed"; all_ok=1 ;;
  esac
done
exit $all_ok
