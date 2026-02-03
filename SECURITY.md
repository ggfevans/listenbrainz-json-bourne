# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.x    | Yes       |

Only the latest release is actively supported with security fixes.

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Instead, please report them through GitHub's private security advisory feature:

1. Go to the [Security Advisories page](https://github.com/ggfevans/listenbrainz-github-action/security/advisories)
2. Click **"New draft security advisory"**
3. Fill in the details of the vulnerability

You should receive an initial response within 72 hours. If the vulnerability is confirmed, a fix will be developed privately and released as a patch before the advisory is made public.

## Scope

This action runs as a composite GitHub Action using bash scripts. It makes read-only HTTP requests to the public ListenBrainz API and writes a JSON file to the caller's repository.

Security-relevant areas include:

- **Input validation** -- all action inputs are validated before use
- **Path traversal** -- the output path is checked against `GITHUB_WORKSPACE`
- **Command injection** -- inputs are restricted to safe character sets
- **Temporary file handling** -- temp files are scoped per run and cleaned up

## Out of Scope

- Vulnerabilities in the ListenBrainz API itself (report those to [MetaBrainz](https://metabrainz.org))
- Vulnerabilities in GitHub Actions runner infrastructure
- Issues requiring the caller to have already misconfigured their workflow permissions
