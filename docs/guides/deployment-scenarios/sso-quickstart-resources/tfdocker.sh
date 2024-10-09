#!/usr/bin/env bash
set -euo pipefail

function aws_creds() {
  local credname
  case $1 in
    id)
      credname=aws_access_key_id ;;
    secret)
      credname=aws_secret_access_key ;;
  esac
  grep $credname ~/.aws/credentials | head -1 | awk '{print $NF}'
}

docker run --rm \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  -e AWS_ACCESS_KEY_ID="$(aws_creds id)" \
  -e AWS_SECRET_ACCESS_KEY="$(aws_creds secret)" \
  hashicorp/terraform:1.9.7 \
  "${@}"