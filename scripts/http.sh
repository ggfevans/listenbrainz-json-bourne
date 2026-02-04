#!/usr/bin/env bash
# http.sh
# Shared HTTP fetch with retry and backoff.
# Source this file, then call fetch_url.

fetch_url() {
  local url="$1" output="$2" max_attempts=2 attempt=0 status
  while [ $attempt -lt $max_attempts ]; do
    status=$(curl -sL --max-redirs 3 -w "%{http_code}" -o "$output" \
      --max-time 30 --connect-timeout 10 "$url") || status="000"
    if [ "$status" -eq 429 ]; then
      local wait=$((2 ** attempt))
      echo "Rate limited (HTTP 429), retrying in ${wait}s..." >&2
      sleep "$wait"
      attempt=$((attempt + 1))
    elif [ "$status" = "000" ] && [ $attempt -eq 0 ]; then
      echo "Connection failed, retrying in 2s..." >&2
      sleep 2
      attempt=$((attempt + 1))
    else
      echo "$status"
      return 0
    fi
  done
  echo "$status"
}
