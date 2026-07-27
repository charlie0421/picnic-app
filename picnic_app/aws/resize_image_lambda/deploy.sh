#!/usr/bin/env bash
set -euo pipefail

echo "NO-GO: direct Lambda mutation is disabled."
echo "Use the approved protected CI deployment at the exact release SHA."
exit 1
