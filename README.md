# Antigravity + LiteLLM Enterprise Gateway Sandbox

> [!IMPORTANT]  
> This project is not provided by Google and does not come with any support or warranties. This project serves as a proof of concept for how it's possible to implement an enterprise gateway with Antigravity.  
> Though functional, you may wish to change the design for increased reliability or feature detail.  

> [!IMPORTANT]  
> Accurate as of 10/15/2026  

A self-contained local developer sandbox demonstrating **Google Antigravity (`agy`)** routing all LLM inference through a local **LiteLLM Enterprise Gateway Proxy** on `localhost:4000`.

---

## 🌟 Key Architecture & Capabilities

* **Zero Interactive Browser OAuth:** Suppresses 3-legged Google login on developer workstations; authentication terminates at the local proxy via an enterprise API key (`AGY_LLM_GATEWAY_API_KEY`).
* **OpenAI Wire Protocol Translation:** Bridges Antigravity client requests (`/v1/chat/completions`) upstream to **Google Cloud Vertex AI** using local Application Default Credentials (ADC).
* **Multi-Model Support:** Configured for `gemini-3.8-flash` (Primary Agent), `gemini-3.1-pro-preview` (Reasoning), and `gemini-3.1-flash-lite` (Fast Utility).
* **Live Attribution:** Preserves client attribution headers (`User-Agent: Antigravity/...`) to draw against governed Gemini Enterprise contracts.

---

## 🚀 Quickstart

### Prerequisites
* Podman (or Docker) with Compose support installed and running.
* Google Cloud CLI (`gcloud`) authenticated with Application Default Credentials:
  ```bash
  gcloud auth application-default login
  ```
  > [!IMPORTANT]
  > Run `gcloud auth application-default login` before launching Podman Compose. If the container runtime starts with a missing host ADC credential file, it auto-creates an empty directory owned by root at that path, breaking future `gcloud` logins until manually removed.

### 1. Configure and Launch the LiteLLM Gateway
```bash
# Optional: copy .env.example to .env
cp .env.example .env

# Export your active GCP project (or specify explicitly in .env)
export VERTEX_PROJECT="$(gcloud config get-value project)"
export VERTEX_LOCATION="us-central1"

# Spin up the proxy container
podman compose up -d
```

### 2. Verify Gateway Ingress
Run the automated preflight and smoke verification helper:
```bash
./verify_setup.sh
```
Or test an individual model (standard or streaming):
```bash
./test_gateway.sh gemini-3.8-flash
./test_gateway.sh --stream gemini-3.8-flash
```

### 3. Connect Antigravity CLI
Source the environment variables in your current shell:
```bash
source env_overrides.sh

# Run Antigravity - notice it executes immediately without Google OAuth prompts
agy prompt "Explain binary search in Go"
```

### 4. Monitor Proxy Logs
Inspect the live stream of requests, tokens, and latency in real time:
```bash
podman compose logs -f litellm
```

---

## ⚙️ Configuration Files

| File | Purpose |
| :--- | :--- |
| `docker-compose.yaml` | Stands up LiteLLM with host ADC volume mount and loopback `127.0.0.1:4000:4000` mapping (used by Podman / Docker Compose) |
| `litellm_config.yaml` | Routes Antigravity model IDs (`gemini-3.8-flash`, etc.) upstream to Vertex AI |
| `env_overrides.sh` | Shell export script for `AGY_LLM_GATEWAY_*` variables (with sourcing guard) |
| `admin_settings.json.template` | Reference template for system-wide `admin_settings.json` (Linux: `/etc/antigravity/`, macOS: `/Library/Application Support/Antigravity/`, Windows: `%ProgramData%\Antigravity\`) |
| `.env.example` | Template for GCP project, location, and gateway master key settings |
| `test_gateway.sh` | Smoke test script using `curl` with streaming option and status validation |
| `verify_setup.sh` | Comprehensive preflight check (ADC, runtime, health, multi-model completions) |

---

## 🛑 Tear Down
```bash
podman compose down
```
