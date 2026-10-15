# Agent Guidelines: Antigravity + LiteLLM Gateway Demo

This repository is an open-source demonstration sandbox pairing Google Antigravity (`agy`) with a local LiteLLM Enterprise Gateway container on `localhost:4000`.

## Architecture & Conventions

* **Client Tooling:** Google Antigravity CLI (`agy`) and Antigravity 2.0 Desktop Hub.
* **Gateway Container:** LiteLLM (`ghcr.io/berriai/litellm:main-latest`) exposing port `4000`.
* **Upstream Provider:** Google Cloud Vertex AI (`us-central1`).
* **Authentication Flow:** Antigravity suppresses interactive OAuth via `AGY_LLM_GATEWAY_URL` and authenticates to LiteLLM via `AGY_LLM_GATEWAY_API_KEY`. LiteLLM uses local GCP Application Default Credentials (`~/.config/gcloud/application_default_credentials.json`).

## Guardrails

* Never commit secrets, service account keys, or API tokens to source control.
* Keep all scripts executable (`chmod +x`).
* Ensure zero internal corporate paths or internal codenames are introduced into this repository.
