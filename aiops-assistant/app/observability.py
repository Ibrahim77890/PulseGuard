from __future__ import annotations

import json
from pathlib import Path
import time
from typing import Any

try:
    from opentelemetry import trace
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
    from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
    from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    OTEL_AVAILABLE = True
except ImportError:  # pragma: no cover - local fallback for environments without optional deps
    OTEL_AVAILABLE = False

    class _NoopSpan:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

        def set_attribute(self, key: str, value: Any) -> None:
            del key, value

    class _NoopTracer:
        def start_as_current_span(self, name: str):
            del name
            return _NoopSpan()

    class _NoopTrace:
        def set_tracer_provider(self, provider: Any) -> None:
            del provider

        def get_tracer(self, name: str):
            del name
            return _NoopTracer()

    class _NoopInstrumentor:
        def instrument(self) -> None:
            return None

        @staticmethod
        def instrument_app(app: Any) -> None:
            del app

    class Resource:
        @staticmethod
        def create(attrs: dict[str, Any]) -> dict[str, Any]:
            return attrs

    class TracerProvider:
        def __init__(self, resource: Any) -> None:
            self.resource = resource

        def add_span_processor(self, processor: Any) -> None:
            del processor

    class BatchSpanProcessor:
        def __init__(self, exporter: Any) -> None:
            self.exporter = exporter

    class OTLPSpanExporter:
        def __init__(self, endpoint: str) -> None:
            self.endpoint = endpoint

    FastAPIInstrumentor = _NoopInstrumentor
    HTTPXClientInstrumentor = _NoopInstrumentor
    trace = _NoopTrace()

try:
    from prometheus_client import Counter, Gauge, Histogram
except ImportError:  # pragma: no cover - local fallback for environments without optional deps
    class _NoopMetric:
        def labels(self, **kwargs):
            del kwargs
            return self

        def inc(self, amount: float = 1) -> None:
            del amount

        def observe(self, amount: float) -> None:
            del amount

        def set(self, amount: float) -> None:
            del amount

    def Counter(*args, **kwargs):
        del args, kwargs
        return _NoopMetric()

    def Gauge(*args, **kwargs):
        del args, kwargs
        return _NoopMetric()

    def Histogram(*args, **kwargs):
        del args, kwargs
        return _NoopMetric()
from starlette.applications import Starlette

from app.config import settings


REQUEST_COUNTER = Counter(
    "pulseguard_aiops_requests_total",
    "Total AIOps assistant requests.",
    labelnames=("route", "model", "outcome"),
)
REQUEST_LATENCY = Histogram(
    "pulseguard_aiops_request_latency_seconds",
    "Latency of AIOps assistant requests.",
    labelnames=("route", "model"),
    buckets=(0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 30, 60),
)
TOOL_CALL_COUNTER = Counter(
    "pulseguard_aiops_tool_calls_total",
    "Total assistant tool calls.",
    labelnames=("tool", "outcome"),
)
TOOL_CALL_LATENCY = Histogram(
    "pulseguard_aiops_tool_call_latency_seconds",
    "Latency of assistant tool calls.",
    labelnames=("tool",),
    buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10),
)
LLM_TOKENS_COUNTER = Counter(
    "pulseguard_aiops_llm_tokens_total",
    "Token usage attributed to LLM requests.",
    labelnames=("model", "direction"),
)
LLM_COST_COUNTER = Counter(
    "pulseguard_aiops_llm_cost_usd_total",
    "Estimated cumulative LLM cost in USD.",
    labelnames=("model",),
)
RETRIEVAL_DOCUMENTS_COUNTER = Counter(
    "pulseguard_aiops_retrieved_documents_total",
    "Documents retrieved by incident memory search.",
    labelnames=("category",),
)
EVAL_SCORE_GAUGE = Gauge(
    "pulseguard_aiops_eval_quality_score",
    "Latest eval quality score as a percentage.",
)
EVAL_TOOL_CORRECTNESS_GAUGE = Gauge(
    "pulseguard_aiops_eval_tool_correctness_score",
    "Latest eval tool correctness score as a percentage.",
)
EVAL_COST_PER_CASE_GAUGE = Gauge(
    "pulseguard_aiops_eval_cost_per_case_usd",
    "Latest average eval cost per case in USD.",
)


def configure_observability(app: Starlette) -> None:
    if OTEL_AVAILABLE and settings.otel_exporter_otlp_endpoint:
        resource = Resource.create(
            {
                "service.name": settings.service_name,
                "service.namespace": "pulseguard",
                "deployment.environment": settings.environment,
            }
        )
        provider = TracerProvider(resource=resource)
        exporter = OTLPSpanExporter(endpoint=settings.otel_exporter_otlp_endpoint)
        provider.add_span_processor(BatchSpanProcessor(exporter))
        trace.set_tracer_provider(provider)

    FastAPIInstrumentor.instrument_app(app)
    HTTPXClientInstrumentor().instrument()
    refresh_eval_metrics()


def get_tracer():
    return trace.get_tracer("pulseguard.aiops.assistant")


def observe_request(route: str, model: str, outcome: str, elapsed_seconds: float) -> None:
    REQUEST_COUNTER.labels(route=route, model=model or "unknown", outcome=outcome).inc()
    REQUEST_LATENCY.labels(route=route, model=model or "unknown").observe(elapsed_seconds)


def observe_tool_call(tool: str, outcome: str, elapsed_seconds: float) -> None:
    TOOL_CALL_COUNTER.labels(tool=tool, outcome=outcome).inc()
    TOOL_CALL_LATENCY.labels(tool=tool).observe(elapsed_seconds)


def observe_retrieval(category: str, document_count: int) -> None:
    if document_count > 0:
        RETRIEVAL_DOCUMENTS_COUNTER.labels(category=category).inc(document_count)


def observe_llm_usage(model: str, input_tokens: int, output_tokens: int, cost_usd: float) -> None:
    if input_tokens:
        LLM_TOKENS_COUNTER.labels(model=model, direction="input").inc(input_tokens)
    if output_tokens:
        LLM_TOKENS_COUNTER.labels(model=model, direction="output").inc(output_tokens)
    if cost_usd > 0:
        LLM_COST_COUNTER.labels(model=model).inc(cost_usd)


def estimate_llm_cost(model: str, input_tokens: int, output_tokens: int) -> float:
    pricing = settings.model_pricing_usd_per_million.get(model, settings.model_pricing_usd_per_million["default"])
    return round(
        ((input_tokens / 1_000_000) * pricing["input"]) + ((output_tokens / 1_000_000) * pricing["output"]),
        8,
    )


def refresh_eval_metrics() -> None:
    path = Path(settings.eval_results_path)
    if not path.exists():
        return

    payload = json.loads(path.read_text(encoding="utf-8"))
    EVAL_SCORE_GAUGE.set(payload.get("quality_score_percent", 0))
    EVAL_TOOL_CORRECTNESS_GAUGE.set(payload.get("tool_correctness_percent", 0))
    EVAL_COST_PER_CASE_GAUGE.set(payload.get("average_cost_usd", 0))


class TimedOperation:
    def __init__(self) -> None:
        self.started_at = time.perf_counter()

    @property
    def elapsed(self) -> float:
        return time.perf_counter() - self.started_at
