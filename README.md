# ListenBrainz Data

A GitHub Action that fetches your ListenBrainz listening data and writes it to a structured JSON file.

## What it does

This action fetches listening data from the ListenBrainz public API -- recent listens, top artists, top tracks, and top albums -- and writes a single structured JSON file to your repository. It is designed for static site generators like Astro that read data from local JSON files at build time. No authentication is needed; ListenBrainz stats are public.

## Usage

```yaml
name: Update Music Data

on:
  schedule:
    - cron: '0 */6 * * *'
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: gvns/listenbrainz-github-action@v1
        with:
          username: your-username

      - name: Commit and push
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'chore: update listenbrainz data'
          file_pattern: src/data/music.json
```

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | Yes | -- | ListenBrainz username |
| `output_path` | No | `src/data/music.json` | Path to write the JSON file |
| `stats_range` | No | `this_month` | Time range for stats (`this_week`, `this_month`, `this_year`, `week`, `month`, `quarter`, `half_yearly`, `all_time`) |
| `top_count` | No | `5` | Number of items in top lists |
| `recent_count` | No | `5` | Number of recent listens |

## Output JSON

The action writes a single JSON file with the following top-level fields:

- `lastUpdated` -- ISO 8601 timestamp
- `recentListens` -- array of recent listens, each with `track`, `artist`, `album`, `listenedAt`, `recordingMbid`, `artistMbids`, `caaReleaseMbid`, and `caaId`
- `recentListensStatus` -- always `"ok"` (fetch failure is fatal)
- `topArtists` -- array of top artists, each with `name`, `listenCount`, and `artistMbid`
- `topArtistsStatus` -- `"ok"`, `"no_data"`, or `"error"`
- `topTracks` -- array of top tracks, each with `track`, `artist`, `listenCount`, `recordingMbid`, `caaReleaseMbid`, and `caaId`
- `topTracksStatus` -- `"ok"`, `"no_data"`, or `"error"`
- `topAlbums` -- array of top albums, each with `album`, `artist`, `listenCount`, `caaReleaseMbid`, and `caaId`
- `topAlbumsStatus` -- `"ok"`, `"no_data"`, or `"error"`
- `stats` -- object with `totalListenCount`, `range`, `artistCount`, `albumCount`, and `trackCount`

Each status field is one of `"ok"`, `"no_data"` (the API returned no stats for the selected range), or `"error"` (the API call failed). Your frontend can use these to decide what to render.

MBIDs and Cover Art Archive IDs are included so you can construct album art URLs on the frontend. For example:

```
https://coverartarchive.org/release/{caaReleaseMbid}/front-250
```

## License

MIT
