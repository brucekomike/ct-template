#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s REMOTE_REPOSITORY[:TAG]\n' "$0" >&2
  exit 1
fi

remote="$1"
remote_name="${remote##*/}"
remote_dir="${remote%/*}"
if [[ "$remote_name" == "$remote" ]]; then
  remote_dir=''
fi
if [[ "$remote_name" == *:* ]]; then
  tag=":${remote_name##*:}"
  remote_name="${remote_name%:*}"
else
  tag=':main'
fi

declare -A pushed=()
while IFS= read -r dockerfile; do
  filename="${dockerfile##*/}"
  name="${filename#Dockerfile}"
  if [[ "$name" =~ ^(.*)\.([0-9]+)$ ]]; then
    name="${BASH_REMATCH[1]}"
  fi
  key="${name:-root}"
  [[ -z "${pushed[$key]+x}" ]] || continue
  pushed["$key"]=1
  image="ct-template${name//./-}:main"
  remote_image="${remote_name}${name//./-}${tag}"
  [[ -n "$remote_dir" ]] && remote_image="${remote_dir}/${remote_image}"
  bin_dir="$(cd "$(dirname "$0")" && pwd)"
  "$bin_dir/push.sh" "$remote_image" "$image"
done < <(find . -type f -name 'Dockerfile*' -not -path './.git/*' | sort -u)
