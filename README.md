# ListenBrainz GitHub Action

A composite GitHub Action that fetches listening data from the [ListenBrainz](https://listenbrainz.org) public API and writes it to a structured JSON file. Built as part of [gvns.ca](https://gvns.ca) ([source](https://github.com/ggfevans/gvns.ca)) and provided as-is.

## What it does

This action hits the ListenBrainz API to pull down your recent listens, top artists, top tracks, and top albums, then writes everything to a single JSON file in your repository and commits the changes. When paired with a static site generator like Astro, this gives you a "live" music data page that updates on a schedule without any server-side runtime.

No authentication is required -- ListenBrainz stats are public.

## Installation

Add a workflow file to your repository (e.g. `.github/workflows/update-music-data.yml`):

```yaml
name: Update Music Data

on:
  schedule:
    - cron: '0 */6 * * *'  # every 6 hours
  workflow_dispatch:        # manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1

      - uses: ggfevans/listenbrainz-github-action@a39e89ecc366d5f8bc90e8d56cdc3d9e6a2237a9 # v1.0.0
        with:
          username: your-listenbrainz-username
```

The action fetches data from ListenBrainz, writes a JSON file, and automatically commits and pushes if the file changed. No separate commit action needed. If the data hasn't changed since the last run, no commit is created.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | Yes | -- | Your ListenBrainz username |
| `output_path` | No | `src/data/music.json` | Path to write the JSON file |
| `stats_range` | No | `this_month` | Time range for stats (`this_week`, `this_month`, `this_year`, `week`, `month`, `quarter`, `half_yearly`, `all_time`) |
| `top_count` | No | `5` | Number of items in top artists/tracks/albums lists |
| `recent_count` | No | `5` | Number of recent listens to include |
| `commit_message` | No | `chore: update listenbrainz data` | Git commit message for auto-commit |
| `skip_commit` | No | `false` | Skip auto-commit (set to `true` to handle commits yourself) |

## Outputs

| Name | Description |
|------|-------------|
| `changes_detected` | `true` if the output file changed, `false` otherwise |
| `file_path` | Repository-relative path to the output file |

Use outputs for conditional downstream steps:

```yaml
- uses: ggfevans/listenbrainz-github-action@a39e89ecc366d5f8bc90e8d56cdc3d9e6a2237a9 # v1.0.0
  id: listenbrainz
  with:
    username: your-listenbrainz-username

- name: Deploy
  if: steps.listenbrainz.outputs.changes_detected == 'true'
  run: echo "Data changed, triggering deploy..."
```

## Advanced: Manual Commits

If you prefer to handle commits yourself (e.g. to combine with other file changes), set `skip_commit: true`:

```yaml
steps:
  - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1

  - uses: ggfevans/listenbrainz-github-action@a39e89ecc366d5f8bc90e8d56cdc3d9e6a2237a9 # v1.0.0
    id: listenbrainz
    with:
      username: your-listenbrainz-username
      skip_commit: true

  - name: Commit and push
    if: steps.listenbrainz.outputs.changes_detected == 'true'
    uses: stefanzweifel/git-auto-commit-action@b863ae1933cb653a53c021fe36dbb774e1fb9403 # v5.2.0
    with:
      commit_message: 'chore: update listenbrainz data'
      file_pattern: ${{ steps.listenbrainz.outputs.file_path }}
```

## Output JSON

The action writes a single JSON file with these fields:

- `lastUpdated` -- ISO 8601 timestamp of when the data was fetched
- `recentListens` -- array of recent listens with `track`, `artist`, `album`, `listenedAt`, `recordingMbid`, `artistMbids`, `caaReleaseMbid`, `caaId`
- `topArtists` -- array with `name`, `listenCount`, `artistMbid`
- `topTracks` -- array with `track`, `artist`, `listenCount`, `recordingMbid`, `caaReleaseMbid`, `caaId`
- `topAlbums` -- array with `album`, `artist`, `listenCount`, `caaReleaseMbid`, `caaId`
- `stats` -- object with `totalListenCount`, `range`, `artistCount`, `albumCount`, `trackCount`

Each section has a corresponding status field (`recentListensStatus`, `topArtistsStatus`, etc.) with one of three values:

- `"ok"` -- data fetched successfully
- `"no_data"` -- ListenBrainz has no stats for the selected range (common for new accounts)
- `"error"` -- the API call failed

The action fails the workflow only if recent listens cannot be fetched. Stats failures are non-fatal -- the arrays will be empty with the appropriate status.

MusicBrainz IDs and Cover Art Archive IDs are passed through so your frontend can construct image URLs:

```
https://coverartarchive.org/release/{caaReleaseMbid}/front-250
```

## AI Disclosure

This project was built with the assistance of AI tools (Claude). The design, specification, and implementation were developed collaboratively with AI-generated code. All code has been reviewed and tested, but use at your own discretion.

## License

MIT -- see [LICENSE](LICENSE) for details.
