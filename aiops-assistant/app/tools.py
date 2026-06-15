import json
import logging
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import httpx

from app.config import settings
from app.knowledge import search_knowledge


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
        url = f"{settings.prometheus_base_url.rstrip('/')}/api/v1/query"
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(url, params={"query": promql})
            response.raise_for_status()
            payload = response.json()

        result = {
            "status": payload.get("status"),
            "result_type": payload.get("data", {}).get("resultType"),
            "result": payload.get("data", {}).get("result", [])[:10],
        }
        _tool_log("query_prometheus", {"promql": promql}, f"{len(result['result'])} series", session_id)
        return result

    async def query_loki(self, session_id: str, logql: str, limit: int = 20) -> dict[str, Any]:
        end = datetime.now(UTC)
        start = end - timedelta(minutes=30)
        url = f"{settings.loki_base_url.rstrip('/')}/loki/api/v1/query_range"
        params = {
            "query": logql,
            "limit": limit,
            "start": str(int(start.timestamp() * 1_000_000_000)),
            "end": str(int(end.timestamp() * 1_000_000_000)),
        }

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            payload = response.json()

        result = {
            "status": payload.get("status"),
            "result_type": payload.get("data", {}).get("resultType"),
            "result": payload.get("data", {}).get("result", [])[:10],
        }
        _tool_log("query_loki", {"logql": logql, "limit": limit}, f"{len(result['result'])} streams", session_id)
        return result

    async def fetch_grafana_status(self, session_id: str) -> dict[str, Any]:
        links = _dashboard_links()
        result = {
            "dashboards": links,
            "recommended_start": links["error_budget"],
        }
        _tool_log("fetch_grafana_status", {}, "returned dashboard links", session_id)
        return result

    async def fetch_runbook(self, session_id: str, runbook_name: str) -> dict[str, Any]:
        path = Path(settings.runbooks_root) / runbook_name
        if not path.exists():
            raise FileNotFoundError(f"Runbook {runbook_name} was not found.")

        content = path.read_text(encoding="utf-8")
        result = {
            "title": content.splitlines()[0].lstrip("# ").strip() if content else runbook_name,
            "source": str(path),
            "content": content[:6000],
        }
        _tool_log("fetch_runbook", {"runbook_name": runbook_name}, result["title"], session_id)
        return result

    async def search_incident_memory(self, session_id: str, query: str) -> dict[str, Any]:
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
        _tool_log("search_incident_memory", {"query": query}, f"{len(result['documents'])} docs", session_id)
        return result


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
