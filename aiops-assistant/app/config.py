from dataclasses import dataclass, field
import json
import os


def _env_flag(name: str, default: str) -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes", "on"}


def _env_csv(name: str, default: str) -> list[str]:
    return [item.strip() for item in os.getenv(name, default).split(",") if item.strip()]


@dataclass
class Settings:
    service_name: str = os.getenv("SERVICE_NAME", "pulseguard-aiops-assistant")
    environment: str = os.getenv("ENVIRONMENT", "dev")
    openrouter_base_url: str = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    openrouter_default_model: str = os.getenv("OPENROUTER_DEFAULT_MODEL", "openai/gpt-4o-mini")
    openrouter_reasoning_model: str = os.getenv("OPENROUTER_REASONING_MODEL", "anthropic/claude-3.5-haiku")
    openrouter_api_key: str = os.getenv("OPENROUTER_API_KEY", "")
    otel_exporter_otlp_endpoint: str = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")
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
    eval_results_path: str = os.getenv("EVAL_RESULTS_PATH", "/app/evals/latest-results.json")
    http_timeout_seconds: int = int(os.getenv("HTTP_TIMEOUT_SECONDS", "15"))
    enable_prompt_guardrails: bool = _env_flag("ENABLE_PROMPT_GUARDRAILS", "true")
    ai_security_audit_logging: bool = _env_flag("AI_SECURITY_AUDIT_LOGGING", "true")
    allowed_outbound_hosts: list[str] = field(
        default_factory=lambda: _env_csv(
            "ALLOWED_OUTBOUND_HOSTS",
            ",".join(
                [
                    "openrouter.ai",
                    "kube-prometheus-stack-prometheus.observability.svc.cluster.local",
                    "loki-gateway.observability.svc.cluster.local",
                    "grafana.observability.svc.cluster.local",
                ]
            ),
        )
    )
    model_pricing_usd_per_million: dict = field(
        default_factory=lambda: json.loads(
            os.getenv(
                "MODEL_PRICING_USD_PER_MILLION",
                json.dumps(
                    {
                        "default": {"input": 0.15, "output": 0.6},
                        "openai/gpt-4o-mini": {"input": 0.15, "output": 0.6},
                        "anthropic/claude-3.5-haiku": {"input": 0.8, "output": 4.0},
                    }
                ),
            )
        )
    )

    def selected_model(self, routing_mode: str, prompt: str) -> str:
        if routing_mode == "cheap":
            return self.openrouter_default_model
        if routing_mode == "deep" or len(prompt) > 300:
            return self.openrouter_reasoning_model
        return self.openrouter_default_model


settings = Settings()
