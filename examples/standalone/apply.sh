#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f tfplan ]; then
  ./plan.sh
fi

terraform apply tfplan
