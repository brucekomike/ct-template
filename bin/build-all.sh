#!/usr/bin/env bash

set -euo pipefail

files=()
while IFS= read -r file; do
  files+=("$file")
done < <(find . -type f -name 'Dockerfile*' -not -path './.git/*' | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  printf 'No Dockerfiles found.\n' >&2
  exit 1
fi

for stage in 0 1 2 3 4; do
  for dockerfile in "${files[@]}"; do
    filename="${dockerfile##*/}"
    name="${filename#Dockerfile}"
    current_stage=0
    if [[ "$name" =~ ^(.*)\.([0-9]+)$ ]]; then
      name="${BASH_REMATCH[1]}"
      current_stage="${BASH_REMATCH[2]}"
    fi
    [[ "$current_stage" -eq "$stage" ]] || continue

    image="ct-template${name//./-}:main"
    args=()
    if [[ "$stage" -gt 0 ]]; then
      args+=(--build-arg "BASE_IMAGE=ct-template${name//./-}:main")
    fi
    docker build --file "$dockerfile" --tag "$image" "${args[@]}" .
  done
done
