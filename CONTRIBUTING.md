# Contributing

Thanks for your interest in contributing to this project.

## Reporting Bugs

Open a [GitHub issue](https://github.com/ggfevans/listenbrainz-github-action/issues/new) with:

- What you expected to happen
- What actually happened
- Your workflow configuration (redact your username if you prefer)
- Any relevant log output from the action run

## Suggesting Features

Open an issue describing the use case. This action is intentionally minimal -- it fetches data from ListenBrainz and writes JSON. Features that add complexity without broad utility may not be accepted.

## Submitting Pull Requests

1. Fork the repository and create a branch from `main`
2. Make your changes
3. Test locally if possible (see below)
4. Open a PR against `main` with a clear description of what changed and why

Keep PRs focused on a single change. If you're fixing a bug and also want to refactor something, open separate PRs.

## Development Setup

The action is pure bash. You need:

- **bash** (4.0+)
- **curl**
- **jq**

There is no build step, no package manager, and no runtime dependencies beyond these.

### Running Locally

You can test the scripts directly by setting the required environment variables:

```bash
export LB_USERNAME="your-listenbrainz-username"
export LB_RECENT_COUNT="5"
export LB_STATS_RANGE="this_month"
export LB_TOP_COUNT="5"
export LB_TMPDIR="$(mktemp -d)"
export LB_OUTPUT_PATH="./test-output/music.json"

bash scripts/fetch-listens.sh
bash scripts/fetch-stats.sh
bash scripts/build-json.sh

cat "$LB_OUTPUT_PATH" | jq .
rm -rf "$LB_TMPDIR"
```

### Code Style

- Use `set -euo pipefail` in all scripts
- Quote all variable expansions
- Validate all inputs before use
- Send error/warning messages to stderr
- Keep scripts focused -- no unnecessary dependencies

## Security Issues

Do not open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md) for reporting instructions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
