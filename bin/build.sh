#!/usr/bin/env bash

set -euo pipefail

dockerfile="${1:-Dockerfile}"
image="${2:-}"

if [[ ! -f "$dockerfile" ]]; then
  printf 'Dockerfile not found: %s\n' "$dockerfile" >&2
  exit 1
fi

if [[ -z "$image" ]]; then
  repository="$(git config --get remote.origin.url 2>/dev/null || true)"
  repository="${repository##*/}"
  repository="${repository%.git}"
  [[ -n "$repository" ]] || repository="$(basename "$(git rev-parse --show-toplevel)")"
  repository="${repository,,}"
  filename="${dockerfile##*/}"
  name="${filename#Dockerfile}"
  if [[ "$name" =~ ^(.*)\.([0-9]+)$ ]]; then
    name="${BASH_REMATCH[1]}"
  fi
  image="${repository}${name//./-}:main"
fi

docker build --file "$dockerfile" --tag "$image" .
