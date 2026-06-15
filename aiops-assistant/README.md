# PulseGuard AIOps Assistant

FastAPI-based Phase 08 service for read-only incident investigation.

## Local run

```powershell
cd e:\pulseguard
python -m venv .venv
.venv\Scripts\activate
pip install -r aiops-assistant\requirements.txt
uvicorn app.main:app --app-dir aiops-assistant --host 0.0.0.0 --port 8080
```

## Required environment

- `PROMETHEUS_BASE_URL`
- `LOKI_BASE_URL`
- `GRAFANA_BASE_URL`
- `OPENROUTER_API_KEY` for live LLM-backed tool calling

## Optional environment

- `MEMORY_BACKEND=redis`
- `REDIS_HOST`
- `REDIS_PORT`
- `RUNBOOKS_ROOT`
- `POSTMORTEMS_ROOT`
