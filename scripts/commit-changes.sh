#!/usr/bin/env bash
set -euo pipefail

# commit-changes.sh
# Detects changes to the output file and optionally commits and pushes.
# Handles both untracked (first run) and modified files. Only git-adds
# the specific output file -- never uses git add -A.
#
# Required env vars:
#   LB_OUTPUT_PATH    - Path to the output JSON file
#   LB_COMMIT_MESSAGE - Git commit message
#   LB_SKIP_COMMIT    - "true" to skip commit/push (outputs are still set)
#   GITHUB_OUTPUT     - GitHub Actions output file

# ---------------------------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------------------------
: "${LB_OUTPUT_PATH:?must be set}"
: "${LB_COMMIT_MESSAGE:?must be set}"
: "${LB_SKIP_COMMIT:?must be set}"
: "${GITHUB_OUTPUT:?must be set}"

# shellcheck source=scripts/validate-inputs.sh
source "$(dirname "$0")/validate-inputs.sh"
validate_output_path "$LB_OUTPUT_PATH"

# ---------------------------------------------------------------------------
# Resolve absolute path for the output (resolve_path from validate-inputs.sh)
# ---------------------------------------------------------------------------
RESOLVED_PATH="$(resolve_path "$LB_OUTPUT_PATH")"

# Compute repo-relative path for output
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  RELATIVE_PATH="${RESOLVED_PATH#"${GITHUB_WORKSPACE}/"}"
else
  RELATIVE_PATH="$LB_OUTPUT_PATH"
fi

echo "file_path=${RELATIVE_PATH}" >> "$GITHUB_OUTPUT"

# ---------------------------------------------------------------------------
# Change detection
# ---------------------------------------------------------------------------
CHANGES_DETECTED="false"

if [ ! -f "$RESOLVED_PATH" ]; then
  echo "Output file not found at ${RESOLVED_PATH}, skipping commit"
  echo "changes_detected=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

if ! git ls-files --error-unmatch -- "$RELATIVE_PATH" > /dev/null 2>&1; then
  # File is untracked (first run)
  CHANGES_DETECTED="true"
  echo "New file detected: ${RELATIVE_PATH}"
elif ! git diff --quiet -- "$RELATIVE_PATH"; then
  # File is tracked and has unstaged modifications
  CHANGES_DETECTED="true"
  echo "File modified: ${RELATIVE_PATH}"
elif ! git diff --cached --quiet -- "$RELATIVE_PATH"; then
  # File is tracked and has staged changes
  CHANGES_DETECTED="true"
  echo "File staged: ${RELATIVE_PATH}"
else
  echo "No changes detected in ${RELATIVE_PATH}"
fi

echo "changes_detected=${CHANGES_DETECTED}" >> "$GITHUB_OUTPUT"

# ---------------------------------------------------------------------------
# Early exit if skip_commit is true or no changes
# ---------------------------------------------------------------------------
if [[ "${LB_SKIP_COMMIT,,}" == "true" ]]; then
  echo "skip_commit is true, skipping commit and push"
  exit 0
fi

if [ "$CHANGES_DETECTED" = "false" ]; then
  echo "No changes to commit"
  exit 0
fi

# ---------------------------------------------------------------------------
# Configure git identity and commit
# ---------------------------------------------------------------------------
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add -- "$RELATIVE_PATH"

if ! git commit -m "$LB_COMMIT_MESSAGE"; then
  echo "::error::Failed to commit changes. The file may already be committed or there may be a git configuration issue." >&2
  exit 1
fi

echo "Pushing changes..."
if ! git push; then
  echo "::error::Failed to push changes. Check that your workflow has 'permissions: contents: write' and that the checkout step uses a token with push access." >&2
  exit 1
fi

echo "commit-changes.sh completed successfully"
