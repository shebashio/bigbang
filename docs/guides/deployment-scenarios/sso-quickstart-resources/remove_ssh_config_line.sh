set -xeo pipefail

SSH_CONFIG_PATH="$1"
INCLUDE_LINE="${2//\//\\/}" # escape fwd slashes with a back slash

if [ -f "$SSH_CONFIG_PATH" ]; then
  if [[ $(uname) == 'Darwin' ]]; then
    echo 'macOS detected'
    sed -i '.bak' "/^$INCLUDE_LINE$/d" "$SSH_CONFIG_PATH"
  else
    echo 'Probably Linux'
    sed -i "/^$INCLUDE_LINE$/d" "$SSH_CONFIG_PATH"
  fi
  echo "Removed Include line from $SSH_CONFIG_PATH"
else
  echo "$SSH_CONFIG_PATH does not exist"
fi
