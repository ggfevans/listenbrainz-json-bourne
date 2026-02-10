#!/usr/bin/env bash
set -euo pipefail

# build-json.sh
# Assembles the final JSON output from intermediate files produced by
# fetch-listens.sh and fetch-stats.sh. No network calls are made.
#
# Required env vars:
#   LB_STATS_RANGE  - Stats time range (e.g. this_week, this_month, this_year, all_time)
#   LB_OUTPUT_PATH  - Path to write the final JSON file
#   LB_TMPDIR       - Temporary directory containing intermediate files

# ---------------------------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------------------------
: "${LB_STATS_RANGE:?must be set}"
: "${LB_OUTPUT_PATH:?must be set}"
: "${LB_TMPDIR:?must be set}"

# shellcheck source=scripts/validate-inputs.sh
source "$(dirname "$0")/validate-inputs.sh"
validate_stats_range "$LB_STATS_RANGE"
validate_output_path "$LB_OUTPUT_PATH"

# ---------------------------------------------------------------------------
# Ensure parent directory of output path exists
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$LB_OUTPUT_PATH")"

# ---------------------------------------------------------------------------
# Assemble the final JSON object
# ---------------------------------------------------------------------------
echo "Building final JSON output at ${LB_OUTPUT_PATH}"

jq -n \
  --argjson listens "$(cat "$LB_TMPDIR/listens.json")" \
  --argjson artists "$(cat "$LB_TMPDIR/artists.json")" \
  --argjson tracks "$(cat "$LB_TMPDIR/recordings.json")" \
  --argjson albums "$(cat "$LB_TMPDIR/releases.json")" \
  --arg artistsStatus "$(cat "$LB_TMPDIR/artists-status.txt")" \
  --arg tracksStatus "$(cat "$LB_TMPDIR/recordings-status.txt")" \
  --arg albumsStatus "$(cat "$LB_TMPDIR/releases-status.txt")" \
  --arg range "$LB_STATS_RANGE" \
  --argjson listenCount "$(cat "$LB_TMPDIR/listen-count.json" 2>/dev/null || echo null)" \
  --argjson rangeListenCount "$(cat "$LB_TMPDIR/range-listen-count.json" 2>/dev/null || echo null)" \
  --argjson artistCount "$(cat "$LB_TMPDIR/artists-total.txt" 2>/dev/null || echo null)" \
  --argjson albumCount "$(cat "$LB_TMPDIR/releases-total.txt" 2>/dev/null || echo null)" \
  --argjson trackCount "$(cat "$LB_TMPDIR/recordings-total.txt" 2>/dev/null || echo null)" \
  '{
    lastUpdated: (now | todate),
    recentListens: $listens,
    recentListensStatus: "ok",
    topArtists: $artists,
    topArtistsStatus: $artistsStatus,
    topTracks: $tracks,
    topTracksStatus: $tracksStatus,
    topAlbums: $albums,
    topAlbumsStatus: $albumsStatus,
    stats: {
      totalListenCount: $listenCount,
      rangeListenCount: $rangeListenCount,
      range: $range,
      artistCount: $artistCount,
      albumCount: $albumCount,
      trackCount: $trackCount
    }
  }' > "$LB_OUTPUT_PATH"

echo "build-json.sh completed successfully"
