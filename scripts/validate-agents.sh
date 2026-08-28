#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [AGENTS.md path]\n' "$(basename "$0")" >&2
  exit 2
fi

agents_file=${1:-AGENTS.md}
failures=0

error() {
  printf 'Error: %s\n' "$1" >&2
  failures=$((failures + 1))
}

if [[ ! -f "$agents_file" ]]; then
  printf 'Error: %s does not exist.\n' "$agents_file" >&2
  exit 1
fi

agents_dir=$(cd "$(dirname "$agents_file")" && pwd -P)
agents_path="${agents_dir}/$(basename "$agents_file")"
repo_root=$(git -C "$agents_dir" rev-parse --show-toplevel 2>/dev/null || true)

if [[ -z "$repo_root" ]]; then
  error "$agents_file is not inside a Git repository."
else
  repo_root=$(cd "$repo_root" && pwd -P)
  if [[ "$agents_path" != "${repo_root}/AGENTS.md" ]]; then
    error "$agents_file must be the repository-root AGENTS.md at ${repo_root}/AGENTS.md."
  elif git -C "$repo_root" check-ignore --no-index -q "$agents_path"; then
    error "$agents_file is ignored by Git."
  fi
fi

heading_count=$(grep -Fxc -- '# AGENTS.md' "$agents_file" || true)
if [[ "$heading_count" -ne 1 ]]; then
  error "$agents_file must contain exactly one '# AGENTS.md' heading."
fi

marker='<!-- big-bang-agents-standard: 1 -->'
marker_count=$(grep -Fxc -- "$marker" "$agents_file" || true)
if [[ "$marker_count" -ne 1 ]]; then
  error "$agents_file must contain exactly one '$marker' marker."
fi

required_sections=(
  'Repository Purpose'
  'Sources of Truth'
  'Repository Layout'
  'Working Rules'
  'Commands'
  'Validation'
  'Big Bang Integration'
  'Authoritative References'
)

previous_line=0
for section in "${required_sections[@]}"; do
  heading="## ${section}"
  count=$(grep -Fxc -- "$heading" "$agents_file" || true)

  if [[ "$count" -ne 1 ]]; then
    error "$agents_file must contain exactly one '$heading' heading."
    continue
  fi

  line=$(grep -Fnx -- "$heading" "$agents_file" | cut -d: -f1)
  if [[ "$line" -le "$previous_line" ]]; then
    error "$heading is out of order in $agents_file."
  fi
  previous_line=$line

  content=$(awk -v heading="$heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*<!--/ { print; exit }
  ' "$agents_file")
  if [[ -z "$content" ]]; then
    error "$heading must not be empty in $agents_file."
  fi
done

if grep -En -- '(CHANGEME|REPLACEME|<repository-name>|<path-to-[^>]+>|<command>)' "$agents_file" >/dev/null; then
  error "$agents_file contains an unresolved template placeholder."
fi

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi

printf 'AGENTS.md validation passed: %s\n' "$agents_file"
