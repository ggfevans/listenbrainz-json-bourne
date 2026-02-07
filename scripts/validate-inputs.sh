#!/usr/bin/env bash
# validate-inputs.sh
# Shared input validation for all scripts.
# Source this file, then call the needed validators.

validate_username() {
  if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid username format. Must be alphanumeric, hyphens, or underscores." >&2
    exit 1
  fi
}

validate_positive_integer() {
  local name="$1" value="$2"
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: ${name} must be a positive integer, got '${value}'" >&2
    exit 1
  fi
}

validate_stats_range() {
  case "$1" in
    this_week|this_month|this_year|week|month|quarter|half_yearly|all_time) ;;
    *) echo "Error: Invalid stats_range '${1}'. Must be one of: this_week, this_month, this_year, week, month, quarter, half_yearly, all_time" >&2; exit 1 ;;
  esac
}

resolve_path() {
  local resolved
  if resolved="$(realpath -m "$1" 2>/dev/null)"; then
    echo "$resolved"
  elif resolved="$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1" 2>/dev/null)"; then
    echo "$resolved"
  else
    local dir
    dir="$(dirname "$1")"
    if [ -d "$dir" ]; then
      echo "$(cd "$dir" && pwd)/$(basename "$1")"
    else
      # Return absolute path even in fallback to ensure consistent validation
      case "$1" in
        /*) echo "$1" ;;
        *)  echo "${PWD}/$1" ;;
      esac
    fi
  fi
}

validate_output_path() {
  local resolved
  resolved="$(resolve_path "$1")"
  if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    if [[ "$resolved" != "${GITHUB_WORKSPACE}"/* ]]; then
      echo "Error: output_path must be within the workspace (${GITHUB_WORKSPACE}), got '${resolved}'" >&2
      exit 1
    fi
  fi
}
