#!/usr/bin/env bash
# Antigravity Enterprise Gateway Environment Configuration
# Usage: source env_overrides.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: env_overrides.sh must be sourced, not executed directly." >&2
  echo "Usage: source env_overrides.sh" >&2
  exit 1
fi

export AGY_LLM_GATEWAY_URL="http://localhost:4000"
export AGY_LLM_GATEWAY_API_KEY="sk-enterprise-demo-key"
export AGY_LLM_GATEWAY_WIRE_PROTOCOL="openai"
export AGY_LLM_GATEWAY_MODELS="gemini-3.8-flash,gemini-3.1-pro-preview,gemini-3.1-flash-lite"
export AGY_LLM_GATEWAY_HEADERS='{"X-Cost-Center": "OpenSource-Demo"}'

echo "=========================================================="
echo " Antigravity Enterprise Gateway Mode Configured"
echo " Gateway URL:       ${AGY_LLM_GATEWAY_URL}"
echo " Wire Protocol:     ${AGY_LLM_GATEWAY_WIRE_PROTOCOL}"
echo " Filtered Models:   ${AGY_LLM_GATEWAY_MODELS}"
echo " Interactive Login: Suppressed"
echo "=========================================================="
