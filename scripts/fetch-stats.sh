#!/usr/bin/env bash
set -euo pipefail

# fetch-stats.sh
# Fetches top artists, recordings, and releases from the ListenBrainz stats API.
# This is NOT on the critical path — individual stat failures are non-fatal.
#
# Required env vars:
#   LB_USERNAME    - ListenBrainz username
#   LB_STATS_RANGE - Stats time range (e.g. this_week, this_month, this_year, all_time)
#   LB_TOP_COUNT   - Number of top items to fetch
#   LB_TMPDIR      - Temporary directory for intermediate files

API_BASE="https://api.listenbrainz.org/1/stats/user"

# ---------------------------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------------------------
: "${LB_USERNAME:?must be set}"
: "${LB_STATS_RANGE:?must be set}"
: "${LB_TOP_COUNT:?must be set}"
: "${LB_TMPDIR:?must be set}"

# shellcheck source=validate-inputs.sh
source "$(dirname "$0")/validate-inputs.sh"
validate_username "$LB_USERNAME"
validate_stats_range "$LB_STATS_RANGE"
validate_positive_integer "top_count" "$LB_TOP_COUNT"

# ---------------------------------------------------------------------------
# HTTP fetch with retry
# ---------------------------------------------------------------------------
fetch_url() {
  local url="$1" output="$2" retries=2 attempt=0 status
  while [ $attempt -lt $retries ]; do
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

# ---------------------------------------------------------------------------
# Create temp directory if it doesn't exist
# ---------------------------------------------------------------------------
mkdir -p "$LB_TMPDIR"

# ---------------------------------------------------------------------------
# fetch_stat: Fetch a single stat type from the API
#
# Arguments:
#   $1 - endpoint suffix (e.g. "artists")
#   $2 - response array key (e.g. "artists")
#   $3 - jq filter for reshaping items
#   $4 - output filename base (e.g. "artists")
#   $5 - total count key (e.g. "total_artist_count")
# ---------------------------------------------------------------------------
fetch_stat() {
  local endpoint="$1"
  local array_key="$2"
  local jq_filter="$3"
  local output_name="$4"
  local total_key="$5"

  local url="${API_BASE}/${LB_USERNAME}/${endpoint}?range=${LB_STATS_RANGE}&count=${LB_TOP_COUNT}"
  local tmp_file="$LB_TMPDIR/${output_name}-response.tmp"

  echo "Fetching ${output_name} for user: ${LB_USERNAME} (range: ${LB_STATS_RANGE}, count: ${LB_TOP_COUNT})"

  local http_status
  http_status=$(fetch_url "$url" "$tmp_file")

  if [ "$http_status" -eq 200 ]; then
    if jq empty "$tmp_file" 2>/dev/null && \
       jq "[.payload.${array_key}[] | ${jq_filter}]" "$tmp_file" > "$LB_TMPDIR/${output_name}.json" 2>/dev/null; then
      echo "ok" > "$LB_TMPDIR/${output_name}-status.txt"
      jq ".payload.${total_key}" "$tmp_file" > "$LB_TMPDIR/${output_name}-total.txt" 2>/dev/null || echo "null" > "$LB_TMPDIR/${output_name}-total.txt"
      local count
      count=$(jq length "$LB_TMPDIR/${output_name}.json")
      echo "Wrote ${count} ${output_name} to ${LB_TMPDIR}/${output_name}.json"
    else
      echo "[]" > "$LB_TMPDIR/${output_name}.json"
      echo "error" > "$LB_TMPDIR/${output_name}-status.txt"
      echo "null" > "$LB_TMPDIR/${output_name}-total.txt"
      echo "Warning: Failed to parse ${output_name} response as expected JSON" >&2
    fi
  elif [ "$http_status" -eq 204 ]; then
    echo "[]" > "$LB_TMPDIR/${output_name}.json"
    echo "no_data" > "$LB_TMPDIR/${output_name}-status.txt"
    echo "null" > "$LB_TMPDIR/${output_name}-total.txt"
    echo "No ${output_name} data available (HTTP 204)" >&2
  else
    echo "[]" > "$LB_TMPDIR/${output_name}.json"
    echo "error" > "$LB_TMPDIR/${output_name}-status.txt"
    echo "null" > "$LB_TMPDIR/${output_name}-total.txt"
    echo "Warning: ListenBrainz API returned HTTP ${http_status} for ${output_name} endpoint" >&2
  fi

  rm -f "$tmp_file"
}

# ---------------------------------------------------------------------------
# Fetch each stat type
# ---------------------------------------------------------------------------
fetch_stat "artists" "artists" \
  '{name: .artist_name, listenCount: .listen_count, artistMbid: (.artist_mbid // null)}' \
  "artists" "total_artist_count"

fetch_stat "recordings" "recordings" \
  '{track: .track_name, artist: .artist_name, listenCount: .listen_count, recordingMbid: (.recording_mbid // null), caaReleaseMbid: (.caa_release_mbid // null), caaId: (.caa_id // null)}' \
  "recordings" "total_recording_count"

fetch_stat "releases" "releases" \
  '{album: .release_name, artist: .artist_name, listenCount: .listen_count, caaReleaseMbid: (.caa_release_mbid // null), caaId: (.caa_id // null)}' \
  "releases" "total_release_count"

echo "fetch-stats.sh completed successfully"
