#!/usr/bin/env bash
# Quick smoke test script for local LiteLLM Antigravity Gateway
set -euo pipefail

GATEWAY_URL="${AGY_LLM_GATEWAY_URL:-http://localhost:4000}"
API_KEY="${AGY_LLM_GATEWAY_API_KEY:-sk-enterprise-demo-key}"
MODEL="${1:-gemini-3.8-flash}"
STREAM="${STREAM:-false}"

if [[ "${1:-}" == "--stream" ]]; then
  STREAM="true"
  MODEL="${2:-gemini-3.8-flash}"
elif [[ "${2:-}" == "--stream" ]]; then
  STREAM="true"
fi

echo "=========================================================="
echo " Testing Gateway Ingress on: ${GATEWAY_URL}"
echo " Target Model:  ${MODEL}"
echo " Stream Mode:   ${STREAM}"
echo "=========================================================="

TMP_BODY=$(mktemp)
trap 'rm -f "${TMP_BODY}"' EXIT

HTTP_STATUS=$(curl -s -N \
  --connect-timeout 5 \
  --max-time 30 \
  -o "${TMP_BODY}" \
  -w "%{http_code}" \
  "${GATEWAY_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Antigravity/1.2.13 (aidev_client; auth_method=gateway)" \
  -d "{
    \"model\": \"${MODEL}\",
    \"stream\": ${STREAM},
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are a helpful coding assistant.\"},
      {\"role\": \"user\", \"content\": \"Reply with: PONG (Gateway operational)\"}
    ],
    \"temperature\": 0.2
  }" 2>/dev/null || echo "000")

if [[ -s "${TMP_BODY}" ]]; then
  cat "${TMP_BODY}"
  echo ""
fi

if [[ "${HTTP_STATUS}" == "200" ]]; then
  echo -e "\n[PASS] Gateway operational (HTTP 200)."
  exit 0
else
  echo -e "\n[FAIL] Gateway returned HTTP ${HTTP_STATUS}." >&2
  exit 1
fi
