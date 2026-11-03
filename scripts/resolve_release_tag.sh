#!/usr/bin/env bash

set -euo pipefail

if [ -n "${CM_TAG:-}" ]; then
  printf '%s\n' "$CM_TAG"
  exit 0
fi

: "${CM_COMMIT:?is unset; cannot recover the release tag for a rebuild}"

# Rebuilds are API-triggered and Codemagic leaves CM_TAG unset. Refresh tags
# when a remote exists, then accept only an unambiguous release tag attached
# directly to the exact commit being rebuilt.
if git remote get-url origin >/dev/null 2>&1; then
  git fetch --force --tags origin >&2
fi

release_tags=$(git tag --points-at "$CM_COMMIT" --list \
  'picnic-v*' 'picnic-staging-v*')
tag_count=$(printf '%s\n' "$release_tags" | awk 'NF { count++ } END { print count + 0 }')

if [ "$tag_count" -ne 1 ]; then
  echo "Expected exactly one release tag on CM_COMMIT for a rebuild; found $tag_count" >&2
  exit 1
fi

printf '%s\n' "$release_tags"
