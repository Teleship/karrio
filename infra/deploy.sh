#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Deploys the Amplify Hosting stack for Karrio Dashboard via CloudFormation.
#
# Prerequisites:
#   - AWS CLI v2 configured with credentials (aws configure or env vars)
#   - A GitHub personal access token with 'repo' scope
#
# Usage:
#   ./infra/deploy.sh                          # Interactive (prompts for token)
#   GITHUB_TOKEN=ghp_xxx ./infra/deploy.sh     # Non-interactive
#
# Environment variables (all optional, with defaults):
#   AWS_REGION                - AWS region (default: eu-west-2)
#   STACK_NAME                - CloudFormation stack name (default: karrio-dashboard)
#   GITHUB_TOKEN              - GitHub PAT with repo scope
#   NEXTAUTH_SECRET           - NextAuth.js secret for session encryption
#   KARRIO_ADMIN_API_KEY      - Karrio admin API key (optional)
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
AWS_REGION="${AWS_REGION:-eu-west-2}"
STACK_NAME="${STACK_NAME:-karrio-dashboard}"
TEMPLATE_FILE="${SCRIPT_DIR}/amplify-stack.yml"

# GitHub token - prompt if not set
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Enter your GitHub personal access token (repo scope):"
  read -rs GITHUB_TOKEN
  echo ""
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GitHub token is required."
  echo "Create one at: https://github.com/settings/tokens/new?scopes=repo"
  exit 1
fi

# NextAuth secret - generate if not set
if [ -z "${NEXTAUTH_SECRET:-}" ]; then
  NEXTAUTH_SECRET=$(openssl rand -hex 32)
  echo "Generated NEXTAUTH_SECRET (save this): ${NEXTAUTH_SECRET}"
fi

# Build parameter overrides as an array for proper quoting
PARAMS=()
PARAMS+=("GitHubOAuthToken=${GITHUB_TOKEN}")
PARAMS+=("NextAuthSecret=${NEXTAUTH_SECRET}")
[ -n "${KARRIO_ADMIN_API_KEY:-}" ] && PARAMS+=("KarrioAdminApiKey=${KARRIO_ADMIN_API_KEY}")

echo "Deploying stack '${STACK_NAME}' to ${AWS_REGION}..."
echo "Template: ${TEMPLATE_FILE}"
echo ""

aws cloudformation deploy \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameter-overrides "${PARAMS[@]}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags \
    Project=teleship \
    Service=karrio-dashboard \
    ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

echo ""
echo "Stack deployed. Fetching outputs..."
echo ""

aws cloudformation describe-stacks \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}" \
  --query "Stacks[0].Outputs" \
  --output table

echo ""
echo "Done! Amplify will auto-deploy when you push to the 'release' branch."
echo "Sandbox auto-deploys from the 'main' branch."
