#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Tears down the Karrio Dashboard Amplify stack.
# ─────────────────────────────────────────────────────────────────────────────

AWS_REGION="${AWS_REGION:-eu-west-2}"
STACK_NAME="${STACK_NAME:-karrio-dashboard}"

echo "WARNING: This will delete the '${STACK_NAME}' CloudFormation stack"
echo "and all associated Amplify resources in ${AWS_REGION}."
echo ""
read -rp "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "Deleting stack '${STACK_NAME}'..."

aws cloudformation delete-stack \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}"

echo "Waiting for stack deletion..."

aws cloudformation wait stack-delete-complete \
  --region "${AWS_REGION}" \
  --stack-name "${STACK_NAME}"

echo "Stack '${STACK_NAME}' deleted successfully."
