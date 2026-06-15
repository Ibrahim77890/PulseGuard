from dataclasses import dataclass
import os


@dataclass
class Settings:
    service_name: str = os.getenv("SERVICE_NAME", "pulseguard-aiops-assistant")
    openrouter_base_url: str = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    openrouter_default_model: str = os.getenv("OPENROUTER_DEFAULT_MODEL", "openai/gpt-4o-mini")
    openrouter_reasoning_model: str = os.getenv("OPENROUTER_REASONING_MODEL", "anthropic/claude-3.5-haiku")
    openrouter_api_key: str = os.getenv("OPENROUTER_API_KEY", "")
    prometheus_base_url: str = os.getenv(
        "PROMETHEUS_BASE_URL",
        "http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090",
    )
    loki_base_url: str = os.getenv("LOKI_BASE_URL", "http://loki-gateway.observability.svc.cluster.local")
    grafana_base_url: str = os.getenv("GRAFANA_BASE_URL", "http://grafana.observability.svc.cluster.local")
    memory_backend: str = os.getenv("MEMORY_BACKEND", "memory")
    redis_host: str = os.getenv("REDIS_HOST", "")
    redis_port: int = int(os.getenv("REDIS_PORT", "6379"))
    redis_password: str = os.getenv("REDIS_PASSWORD", "")
    redis_session_ttl_seconds: int = int(os.getenv("REDIS_SESSION_TTL_SECONDS", "21600"))
    session_history_limit: int = int(os.getenv("SESSION_HISTORY_LIMIT", "14"))
    runbooks_root: str = os.getenv("RUNBOOKS_ROOT", "/app/docs/runbooks")
    postmortems_root: str = os.getenv("POSTMORTEMS_ROOT", "/app/docs/postmortems")
    http_timeout_seconds: int = int(os.getenv("HTTP_TIMEOUT_SECONDS", "15"))

    def selected_model(self, routing_mode: str, prompt: str) -> str:
        if routing_mode == "cheap":
            return self.openrouter_default_model
        if routing_mode == "deep" or len(prompt) > 300:
            return self.openrouter_reasoning_model
        return self.openrouter_default_model


settings = Settings()
