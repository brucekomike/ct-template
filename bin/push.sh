#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: %s REMOTE_REPOSITORY [LOCAL_IMAGE]\n' "$0" >&2
  exit 1
fi

remote="$1"
local="${2:-$remote}"

# Docker treats an omitted tag as latest; make it explicit for docker tag.
if [[ "$remote" != *@* && "$remote" != *:* ]]; then
  remote="${remote}:latest"
fi
if [[ "$local" != *@* && "$local" != *:* ]]; then
  local="${local}:latest"
fi

if [[ "$local" != "$remote" ]]; then
  docker tag "$local" "$remote"
fi
docker push "$remote"
