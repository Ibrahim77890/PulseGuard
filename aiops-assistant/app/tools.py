import json
import logging
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import httpx

from app.config import settings
from app.knowledge import search_knowledge
from app.observability import TimedOperation, observe_retrieval, observe_tool_call
from app.security import (
    audit_security_event,
    enforce_outbound_host_allowlist,
    enforce_repo_path_boundary,
    sanitize_tool_payload,
)


logger = logging.getLogger("pulseguard.aiops.tools")


def _tool_log(name: str, args: dict[str, Any], result_summary: str, session_id: str) -> None:
    logger.info(
        json.dumps(
            {
                "category": "aiops-tool-call",
                "tool_name": name,
                "session_id": session_id,
                "args": args,
                "result_summary": result_summary,
                "timestamp": datetime.now(UTC).isoformat(),
            }
        )
    )


def _dashboard_links() -> dict[str, str]:
    base = settings.grafana_base_url.rstrip("/")
    return {
        "red": f"{base}/d/pulseguard-red-services/pulseguard-red-services",
        "use": f"{base}/d/pulseguard-use-cluster/pulseguard-use-cluster",
        "error_budget": f"{base}/d/pulseguard-error-budget-overview/pulseguard-error-budget-overview",
        "security": f"{base}/d/pulseguard-security-operations-overview/pulseguard-security-operations-overview",
        "cost": f"{base}/d/pulseguard-cost-overview/pulseguard-cost-overview",
    }


class ReadOnlyTools:
    def __init__(self) -> None:
        self.timeout = httpx.Timeout(settings.http_timeout_seconds)

    async def query_prometheus(self, session_id: str, promql: str) -> dict[str, Any]:
        timer = TimedOperation()
        url = f"{settings.prometheus_base_url.rstrip('/')}/api/v1/query"
        enforce_outbound_host_allowlist(url, session_id, "query_prometheus")
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, params={"query": promql})
                response.raise_for_status()
                payload = response.json()
        except Exception:
            observe_tool_call("query_prometheus", "error", timer.elapsed)
            raise

        result = {
            "status": payload.get("status"),
            "result_type": payload.get("data", {}).get("resultType"),
            "result": payload.get("data", {}).get("result", [])[:10],
        }
        result = sanitize_tool_payload(result)
        _tool_log("query_prometheus", {"promql": promql}, f"{len(result['result'])} series", session_id)
        observe_tool_call("query_prometheus", "success", timer.elapsed)
        return result

    async def query_loki(self, session_id: str, logql: str, limit: int = 20) -> dict[str, Any]:
        timer = TimedOperation()
        end = datetime.now(UTC)
        start = end - timedelta(minutes=30)
        url = f"{settings.loki_base_url.rstrip('/')}/loki/api/v1/query_range"
        enforce_outbound_host_allowlist(url, session_id, "query_loki")
        params = {
            "query": logql,
            "limit": limit,
            "start": str(int(start.timestamp() * 1_000_000_000)),
            "end": str(int(end.timestamp() * 1_000_000_000)),
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            observe_tool_call("query_loki", "error", timer.elapsed)
            raise

        result = {
            "status": payload.get("status"),
            "result_type": payload.get("data", {}).get("resultType"),
            "result": payload.get("data", {}).get("result", [])[:10],
        }
        result = sanitize_tool_payload(result)
        _tool_log("query_loki", {"logql": logql, "limit": limit}, f"{len(result['result'])} streams", session_id)
        observe_tool_call("query_loki", "success", timer.elapsed)
        return result

    async def fetch_grafana_status(self, session_id: str) -> dict[str, Any]:
        timer = TimedOperation()
        try:
            links = _dashboard_links()
            enforce_outbound_host_allowlist(settings.grafana_base_url, session_id, "fetch_grafana_status")
            result = {
                "dashboards": links,
                "recommended_start": links["error_budget"],
            }
            result = sanitize_tool_payload(result)
            _tool_log("fetch_grafana_status", {}, "returned dashboard links", session_id)
            observe_tool_call("fetch_grafana_status", "success", timer.elapsed)
            return result
        except Exception:
            observe_tool_call("fetch_grafana_status", "error", timer.elapsed)
            raise

    async def fetch_runbook(self, session_id: str, runbook_name: str) -> dict[str, Any]:
        timer = TimedOperation()
        root = Path(settings.runbooks_root)
        path = root / runbook_name
        enforce_repo_path_boundary(path, root, session_id, "fetch_runbook")
        if not path.exists():
            observe_tool_call("fetch_runbook", "error", timer.elapsed)
            raise FileNotFoundError(f"Runbook {runbook_name} was not found.")

        content = path.read_text(encoding="utf-8")
        result = {
            "title": content.splitlines()[0].lstrip("# ").strip() if content else runbook_name,
            "source": str(path),
            "content": content[:6000],
        }
        result = sanitize_tool_payload(result)
        _tool_log("fetch_runbook", {"runbook_name": runbook_name}, result["title"], session_id)
        observe_tool_call("fetch_runbook", "success", timer.elapsed)
        return result

    async def search_incident_memory(self, session_id: str, query: str) -> dict[str, Any]:
        timer = TimedOperation()
        try:
            matches = search_knowledge(query, limit=3)
            result = {
                "documents": [
                    {
                        "title": document.title,
                        "source": document.source,
                        "category": document.category,
                        "score": round(score, 4),
                        "excerpt": document.content[:500],
                    }
                    for document, score in matches
                ]
            }
            result = sanitize_tool_payload(result)
            for document, _ in matches:
                observe_retrieval(document.category, 1)
            _tool_log("search_incident_memory", {"query": query}, f"{len(result['documents'])} docs", session_id)
            audit_security_event(
                category="aiops-action-audit",
                action="search_incident_memory",
                session_id=session_id,
                outcome="success",
                details={"documents_returned": len(result["documents"])},
            )
            observe_tool_call("search_incident_memory", "success", timer.elapsed)
            return result
        except Exception:
            observe_tool_call("search_incident_memory", "error", timer.elapsed)
            raise


TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "query_prometheus",
            "description": "Run a read-only PromQL query against PulseGuard Prometheus.",
            "parameters": {
                "type": "object",
                "properties": {"promql": {"type": "string"}},
                "required": ["promql"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "query_loki",
            "description": "Run a read-only LogQL query against PulseGuard Loki.",
            "parameters": {
                "type": "object",
                "properties": {
                    "logql": {"type": "string"},
                    "limit": {"type": "integer", "default": 20},
                },
                "required": ["logql"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_grafana_status",
            "description": "Return the main Grafana dashboard links relevant to incident triage.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_runbook",
            "description": "Fetch the full text of a runbook from the PulseGuard repo.",
            "parameters": {
                "type": "object",
                "properties": {"runbook_name": {"type": "string"}},
                "required": ["runbook_name"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "search_incident_memory",
            "description": "Search past runbooks and postmortems for similar incidents.",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
        },
    },
]
