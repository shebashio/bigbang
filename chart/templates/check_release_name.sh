#!/bin/bash

echo "Checking HelmRelease files and inserting missing releaseName fields..."

# Base path for relative formatting
base_path="$(pwd)"

# Find all helmrelease.yaml files
find . -type f -iname 'helmrelease.yaml' | while read -r file; do
  rel_path="${file#$base_path/}"
  dir_name=$(basename "$(dirname "$file")")

  # Check if releaseName exists (not commented)
  has_release_name=$(grep -E '^[[:space:]]*releaseName:' "$file")

  if [[ -n "$has_release_name" ]]; then
    echo "[FOUND] releaseName in: $rel_path"
  else
    echo "[ADDING] releaseName to: $rel_path (value: $dir_name)"

    # Use awk to insert 'releaseName: <dir_name>' after the 'targetNamespace:' line
    tmp_file=$(mktemp)

    awk -v rn="$dir_name" '
      {
        print $0
        if ($0 ~ /^[[:space:]]*targetNamespace:/) {
          indent = match($0, /[^ ]/) - 1
          printf "%*sreleaseName: %s\n", indent, "", rn
        }
      }
    ' "$file" > "$tmp_file"

    mv "$tmp_file" "$file"
  fi
done
