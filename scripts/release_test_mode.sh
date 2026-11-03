#!/usr/bin/env bash

set -euo pipefail

release_tag="${1:?release tag is required}"

case "$release_tag" in
  picnic-v*-skip-tests|picnic-staging-v*-skip-tests)
    echo "skip"
    ;;
  picnic-v*|picnic-staging-v*)
    echo "run"
    ;;
  *)
    echo "Unknown release tag; refusing to choose a test mode" >&2
    exit 1
    ;;
esac
