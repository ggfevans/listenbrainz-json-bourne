#!/usr/bin/env bash
set -euo pipefail

# fetch-listens.sh
# Fetches recent listens and total listen count from the ListenBrainz API.
# This is the critical path — if fetching listens fails, the action fails.
#
# Required env vars:
#   LB_USERNAME      - ListenBrainz username
#   LB_RECENT_COUNT  - Number of recent listens to fetch
#   LB_TMPDIR        - Temporary directory for intermediate files

API_BASE="https://api.listenbrainz.org/1/user"

# ---------------------------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------------------------
: "${LB_USERNAME:?must be set}"
: "${LB_RECENT_COUNT:?must be set}"
: "${LB_TMPDIR:?must be set}"

# ---------------------------------------------------------------------------
# 1. Create temp directory if it doesn't exist
# ---------------------------------------------------------------------------
mkdir -p "$LB_TMPDIR"

# ---------------------------------------------------------------------------
# 2-4. Fetch recent listens, check status, transform with jq
# ---------------------------------------------------------------------------
echo "Fetching recent listens for user: ${LB_USERNAME} (count: ${LB_RECENT_COUNT})"

HTTP_STATUS=$(curl -s -w "%{http_code}" -o "$LB_TMPDIR/listens-response.tmp" \
  --max-time 30 --connect-timeout 10 \
  "${API_BASE}/${LB_USERNAME}/listens?count=${LB_RECENT_COUNT}")

if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: ListenBrainz API returned HTTP ${HTTP_STATUS} for listens endpoint" >&2
  cat "$LB_TMPDIR/listens-response.tmp" 2>/dev/null >&2
  rm -f "$LB_TMPDIR/listens-response.tmp"
  exit 1
fi

# ---------------------------------------------------------------------------
# 5. Extract and reshape listens, write to listens.json
# ---------------------------------------------------------------------------
jq '[.payload.listens[] | {
  track: .track_metadata.track_name,
  artist: .track_metadata.artist_name,
  album: .track_metadata.release_name,
  listenedAt: (.listened_at | todate),
  caaReleaseMbid: (.track_metadata.mbid_mapping.caa_release_mbid // null),
  caaId: (.track_metadata.mbid_mapping.caa_id // null),
  recordingMbid: (.track_metadata.mbid_mapping.recording_mbid // null),
  artistMbids: (.track_metadata.mbid_mapping.artist_mbids // [])
}]' "$LB_TMPDIR/listens-response.tmp" > "$LB_TMPDIR/listens.json"

rm -f "$LB_TMPDIR/listens-response.tmp"

LISTEN_COUNT=$(jq length "$LB_TMPDIR/listens.json")
echo "Wrote ${LISTEN_COUNT} listens to ${LB_TMPDIR}/listens.json"

# ---------------------------------------------------------------------------
# 6. Fetch total listen count (non-fatal)
# ---------------------------------------------------------------------------
echo "Fetching total listen count for user: ${LB_USERNAME}"

COUNT_STATUS=$(curl -s -w "%{http_code}" -o "$LB_TMPDIR/count-response.tmp" \
  --max-time 30 --connect-timeout 10 \
  "${API_BASE}/${LB_USERNAME}/listen-count")

if [ "$COUNT_STATUS" -eq 200 ]; then
  jq '.payload.count' "$LB_TMPDIR/count-response.tmp" > "$LB_TMPDIR/listen-count.json"
  TOTAL=$(cat "$LB_TMPDIR/listen-count.json")
  echo "Total listen count: ${TOTAL}"
else
  echo "Warning: Could not fetch listen count (HTTP ${COUNT_STATUS}), skipping" >&2
fi

rm -f "$LB_TMPDIR/count-response.tmp"

echo "fetch-listens.sh completed successfully"
