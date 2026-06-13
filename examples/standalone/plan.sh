#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not in PATH." >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is not installed or not in PATH." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Azure CLI is not logged in. Run: az login" >&2
  exit 1
fi

if ! az account get-access-token --resource https://management.azure.com/ >/dev/null 2>&1; then
  echo "Azure CLI token is expired or invalid. Run: az login" >&2
  exit 1
fi

terraform init -input=false
terraform validate
terraform plan -input=false -out=tfplan

echo "Plan saved to: $(pwd)/tfplan"
