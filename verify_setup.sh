#!/usr/bin/env bash
# ==============================================================================
# Antigravity + LiteLLM Enterprise Gateway Verification Helper
# Verifies host prerequisites, gateway health, model catalog, and completions.
# ==============================================================================
set -euo pipefail

GATEWAY_URL="${AGY_LLM_GATEWAY_URL:-http://localhost:4000}"
API_KEY="${AGY_LLM_GATEWAY_API_KEY:-sk-enterprise-demo-key}"
ADC_PATH="${GOOGLE_APPLICATION_CREDENTIALS:-${HOME}/.config/gcloud/application_default_credentials.json}"
MODELS=("gemini-3.8-flash" "gemini-3.1-pro-preview" "gemini-3.1-flash-lite")
ERRORS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass() { echo -e "  [${GREEN}PASS${NC}] $1"; }
fail() { echo -e "  [${RED}FAIL${NC}] $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  [${YELLOW}WARN${NC}] $1"; }
info() { echo -e "  [${BLUE}INFO${NC}] $1"; }

echo "=========================================================="
echo " Antigravity + LiteLLM Gateway Preflight & Smoke Test"
echo " Target URL: ${GATEWAY_URL}"
echo "=========================================================="

echo -e "\n1. Checking Host Prerequisites..."

# Check Application Default Credentials
if [[ -d "${ADC_PATH}" ]]; then
  fail "Application Default Credentials path is a directory (corrupted by prior container mount): ${ADC_PATH}"
  echo "      Fix by removing: rm -rf '${ADC_PATH}' && gcloud auth application-default login"
elif [[ -f "${ADC_PATH}" ]]; then
  pass "Application Default Credentials found at ${ADC_PATH}"
else
  fail "Missing Application Default Credentials at ${ADC_PATH}"
  echo "      Run: gcloud auth application-default login"
fi

# Check Container Runtime
if command -v podman &>/dev/null; then
  pass "Container runtime found: podman ($(podman --version 2>/dev/null | head -n1))"
elif command -v docker &>/dev/null; then
  pass "Container runtime found: docker ($(docker --version 2>/dev/null | head -n1))"
else
  warn "Neither podman nor docker found in PATH"
fi

# Check Project Configuration
PROJECT_ID="${VERTEX_PROJECT:-}"
if [[ -z "${PROJECT_ID}" ]] && [[ -f .env ]]; then
  PROJECT_ID=$(grep -E '^VERTEX_PROJECT=' .env 2>/dev/null | cut -d '=' -f2- | tr -d ' "' || true)
fi
if [[ -z "${PROJECT_ID}" ]] && command -v gcloud &>/dev/null; then
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
fi

if [[ -n "${PROJECT_ID}" && "${PROJECT_ID}" != "your-gcp-project-id" ]]; then
  pass "Target GCP Vertex Project: ${PROJECT_ID}"
else
  fail "VERTEX_PROJECT is not set or using placeholder. Set it in .env or via export VERTEX_PROJECT=..."
fi

# Check Antigravity CLI environment
if [[ -n "${AGY_LLM_GATEWAY_URL:-}" ]]; then
  pass "Antigravity environment overrides active (AGY_LLM_GATEWAY_URL=${AGY_LLM_GATEWAY_URL})"
else
  info "Shell environment overrides not active in this subshell (run: source env_overrides.sh)"
fi

echo -e "\n2. Checking Gateway Connectivity..."

if curl -s -f -o /dev/null --connect-timeout 5 --max-time 10 "${GATEWAY_URL}/health/liveliness" 2>/dev/null || \
   curl -s -f -o /dev/null --connect-timeout 5 --max-time 10 "${GATEWAY_URL}/health" 2>/dev/null; then
  pass "Gateway endpoint is responsive (${GATEWAY_URL})"
else
  fail "Gateway is not currently reachable on ${GATEWAY_URL}"
  echo "      To launch the gateway: podman compose up -d (or podman-compose up -d)"
  echo "      Skipping live inference test."
  echo -e "\n=========================================================="
  echo -e " ${RED}Verification Incomplete (${ERRORS} failure(s))${NC}"
  echo "=========================================================="
  exit 1
fi

echo -e "\n3. Inspecting Registered Model Catalog..."
TMP_MODELS=$(mktemp)
trap 'rm -f "${TMP_MODELS}"' EXIT

MODELS_HTTP=$(curl -s --connect-timeout 5 --max-time 15 \
  -o "${TMP_MODELS}" \
  -w "%{http_code}" \
  "${GATEWAY_URL}/v1/models" \
  -H "Authorization: Bearer ${API_KEY}" 2>/dev/null || echo "000")

if [[ "${MODELS_HTTP}" == "200" ]]; then
  pass "Retrieved model list from gateway (HTTP 200)"
  if command -v jq &>/dev/null; then
    jq -r '.data[].id' "${TMP_MODELS}" 2>/dev/null | sed 's/^/      - /' || cat "${TMP_MODELS}"
  fi
else
  fail "Could not retrieve models list (HTTP ${MODELS_HTTP})"
  cat "${TMP_MODELS}" 2>/dev/null || true
fi

echo -e "\n4. Running Smoke Tests Across Configured Models..."
for MODEL in "${MODELS[@]}"; do
  echo -n "  Testing model: ${MODEL} ... "
  TMP_OUT=$(mktemp)
  HTTP_STATUS=$(curl -s -w "%{http_code}" \
    --connect-timeout 5 \
    --max-time 30 \
    -o "${TMP_OUT}" \
    "${GATEWAY_URL}/v1/chat/completions" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: Antigravity/1.2.13 (aidev_client; auth_method=gateway)" \
    -d "{
      \"model\": \"${MODEL}\",
      \"messages\": [
        {\"role\": \"user\", \"content\": \"Reply with: PONG\"}
      ],
      \"max_tokens\": 10,
      \"temperature\": 0.1
    }" 2>/dev/null || echo "000")

  if [[ "${HTTP_STATUS}" == "200" ]]; then
    echo -e "${GREEN}OK (HTTP 200)${NC}"
  else
    echo -e "${RED}FAILED (HTTP ${HTTP_STATUS})${NC}"
    if [[ -s "${TMP_OUT}" ]]; then
      sed 's/^/      /' "${TMP_OUT}" | head -n 5
    fi
    ERRORS=$((ERRORS + 1))
  fi
  rm -f "${TMP_OUT}"
done

if [[ "${ERRORS}" -eq 0 ]]; then
  echo -e "\n=========================================================="
  echo -e " ${GREEN}Verification Succeeded (0 errors)${NC}"
  echo -e "=========================================================="
  exit 0
else
  echo -e "\n=========================================================="
  echo -e " ${RED}Verification Failed (${ERRORS} error(s))${NC}"
  echo -e "=========================================================="
  exit 1
fi
