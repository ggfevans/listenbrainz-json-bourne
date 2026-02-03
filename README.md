# ListenBrainz GitHub Action

A composite GitHub Action that fetches listening data from the [ListenBrainz](https://listenbrainz.org) public API and writes it to a structured JSON file. Built as part of [gvns.ca](https://gvns.ca) ([source](https://github.com/ggfevans/gvns.ca)) and provided as-is.

## What it does

This action hits the ListenBrainz API to pull down your recent listens, top artists, top tracks, and top albums, then writes everything to a single JSON file in your repository. When paired with a commit step and a static site generator like Astro, this gives you a "live" music data page that updates on a schedule without any server-side runtime.

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
      - uses: actions/checkout@v4

      - uses: ggfevans/listenbrainz-github-action@v1
        with:
          username: your-listenbrainz-username

      - name: Commit and push
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'chore: update listenbrainz data'
          file_pattern: src/data/music.json
```

The action writes the JSON file. Committing and pushing is handled separately -- the example above uses [git-auto-commit-action](https://github.com/stefanzweifel/git-auto-commit-action), but you can use whatever commit strategy you prefer.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | Yes | -- | Your ListenBrainz username |
| `output_path` | No | `src/data/music.json` | Path to write the JSON file |
| `stats_range` | No | `this_month` | Time range for stats (`this_week`, `this_month`, `this_year`, `week`, `month`, `quarter`, `half_yearly`, `all_time`) |
| `top_count` | No | `5` | Number of items in top artists/tracks/albums lists |
| `recent_count` | No | `5` | Number of recent listens to include |

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
