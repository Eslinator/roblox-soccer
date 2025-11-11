#!/usr/bin/env bash
set -u  # no -e so we can handle errors

UNIVERSE_ID=9141685747
PLACE_ID=75007363352132
FILE="build/RobloxSoccer.rbxlx"

# Ensure we have a fresh build
mkdir -p build
rojo build -o "$FILE" >/dev/null

# Get API key if not exported yet (input hidden)
if [[ -z "${ROBLOX_API_KEY:-}" && -z "${RBXCLOUD_API_KEY:-}" ]]; then
  printf "Paste ROBLOX_API_KEY (hidden): "
  read -rs ROBLOX_API_KEY; echo
  export ROBLOX_API_KEY
fi
# rbxcloud also reads RBXCLOUD_API_KEY; set it for convenience
export RBXCLOUD_API_KEY="${RBXCLOUD_API_KEY:-${ROBLOX_API_KEY:-}}"

attempt=1
max=12        # up to ~10–15 minutes worst-case
backoff=5     # seconds; doubles each retry

while (( attempt <= max )); do
  echo "Attempt $attempt/$max …"
  # Try publish
  out=$(rbxcloud experience publish \
    --universe-id "$UNIVERSE_ID" \
    --place-id "$PLACE_ID" \
    --filename "$FILE" \
    --version-type published 2>&1) && status=0 || status=$?

  # Success path
  if (( status == 0 )); then
    echo "✅ Published:"
    echo "$out"
    exit 0
  fi

  # Detect 409 busy or transport hiccups
  if echo "$out" | grep -qE 'http 409|Server is busy|try again|EOF|timeout|connection reset'; then
    sleep_for=$(( backoff + (RANDOM % 7) ))
    echo "Transient ($status). Backing off ${sleep_for}s…"
    sleep "$sleep_for"
    backoff=$(( backoff * 2 ))
    attempt=$(( attempt + 1 ))
    continue
  fi

  # Hard failure (auth/scopes/IDs): print and stop
  echo "❌ Hard error; not retrying:"
  echo "$out"
  exit 1
done

echo "❌ Gave up after $max attempts."
exit 1
