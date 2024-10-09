#!/usr/bin/env bash

docker run --rm \
  -v "$(pwd):$(pwd)" \
  -v "$HOME/.ssh:$HOME/.ssh" \
  -w "$(pwd)" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  hashicorp/terraform:1.9.7 \
  "${@}"