import json
import logging
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from app.config import settings


logger = logging.getLogger("pulseguard.aiops.security")

PROMPT_INJECTION_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"ignore (all|any|the|previous) (instructions|prompts|messages)",
        r"(reveal|print|show).*(system prompt|developer message|hidden prompt)",
        r"\btool[_ -]?call\b",
        r"\bassistant:\b",
        r"\bsystem:\b",
        r"\bdeveloper:\b",
        r"act as",
        r"override",
    ]
]

EXECUTION_CLAIM_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"\b(i|we)\s+(deployed|restarted|rolled back|patched|updated|changed|fixed|executed)\b",
        r"\b(the issue is resolved|incident resolved)\b",
    ]
]


class SecurityPolicyViolation(ValueError):
    pass


def audit_security_event(
    category: str,
    action: str,
    session_id: str,
    outcome: str,
    details: dict[str, Any] | None = None,
) -> None:
    if not settings.ai_security_audit_logging:
        return

    logger.info(
        json.dumps(
            {
                "category": category,
                "action": action,
                "session_id": session_id,
                "outcome": outcome,
                "details": details or {},
                "timestamp": datetime.now(UTC).isoformat(),
            }
        )
    )


def _matches_prompt_injection(text: str) -> bool:
    return any(pattern.search(text) for pattern in PROMPT_INJECTION_PATTERNS)


def contains_prompt_injection(text: str) -> bool:
    if not settings.enable_prompt_guardrails:
        return False
    return _matches_prompt_injection(text)


def sanitize_untrusted_text(text: str, max_length: int = 4000) -> str:
    if not text:
        return text

    sanitized_lines: list[str] = []
    for line in text.splitlines():
        if contains_prompt_injection(line):
            sanitized_lines.append("[redacted suspicious instruction-like content from untrusted source]")
        else:
            sanitized_lines.append(line)

    return "\n".join(sanitized_lines)[:max_length]


def sanitize_tool_payload(payload: Any) -> Any:
    if isinstance(payload, str):
        return sanitize_untrusted_text(payload, max_length=6000)
    if isinstance(payload, list):
        return [sanitize_tool_payload(item) for item in payload]
    if isinstance(payload, dict):
        return {key: sanitize_tool_payload(value) for key, value in payload.items()}
    return payload


def enforce_outbound_host_allowlist(url: str, session_id: str, tool_name: str) -> None:
    host = (urlparse(url).hostname or "").lower()
    allowed_hosts = {item.lower() for item in settings.allowed_outbound_hosts}
    if host in allowed_hosts:
        audit_security_event(
            category="aiops-guardrail-event",
            action="allow_outbound_host",
            session_id=session_id,
            outcome="allowed",
            details={"tool_name": tool_name, "host": host},
        )
        return

    audit_security_event(
        category="aiops-guardrail-event",
        action="allow_outbound_host",
        session_id=session_id,
        outcome="blocked",
        details={"tool_name": tool_name, "host": host},
    )
    raise SecurityPolicyViolation(f"Outbound host {host or '<empty>'} is not in the allowlist.")


def enforce_repo_path_boundary(path: Path, root: Path, session_id: str, tool_name: str) -> None:
    resolved_path = path.resolve()
    resolved_root = root.resolve()

    try:
        resolved_path.relative_to(resolved_root)
    except ValueError as error:
        audit_security_event(
            category="aiops-guardrail-event",
            action="repo_path_boundary",
            session_id=session_id,
            outcome="blocked",
            details={"tool_name": tool_name, "path": str(resolved_path), "root": str(resolved_root)},
        )
        raise SecurityPolicyViolation(f"Path {resolved_path} escapes the permitted root {resolved_root}.") from error


def validate_tool_call(name: str, args: dict[str, Any], session_id: str) -> None:
    if name == "query_prometheus":
        promql = args.get("promql", "")
        if not isinstance(promql, str) or not promql.strip():
            raise SecurityPolicyViolation("Prometheus query must be a non-empty string.")
    elif name == "query_loki":
        logql = args.get("logql", "")
        limit = args.get("limit", 20)
        if not isinstance(logql, str) or not logql.strip():
            raise SecurityPolicyViolation("Loki query must be a non-empty string.")
        if not isinstance(limit, int) or limit < 1 or limit > 100:
            raise SecurityPolicyViolation("Loki limit must be between 1 and 100.")
    elif name == "fetch_runbook":
        runbook_name = args.get("runbook_name", "")
        if not isinstance(runbook_name, str) or not runbook_name.endswith(".md") or "/" in runbook_name or "\\" in runbook_name:
            raise SecurityPolicyViolation("Runbook requests must target a single markdown file in the runbooks root.")
    elif name == "search_incident_memory":
        query = args.get("query", "")
        if not isinstance(query, str) or not query.strip():
            raise SecurityPolicyViolation("Incident-memory query must be a non-empty string.")
    elif name != "fetch_grafana_status":
        raise SecurityPolicyViolation(f"Unsupported tool requested: {name}")

    audit_security_event(
        category="aiops-guardrail-event",
        action="validate_tool_call",
        session_id=session_id,
        outcome="allowed",
        details={"tool_name": name},
    )


def sanitize_final_answer(answer: str, session_id: str) -> str:
    if not answer:
        return answer

    if any(pattern.search(answer) for pattern in EXECUTION_CLAIM_PATTERNS):
        audit_security_event(
            category="aiops-guardrail-event",
            action="sanitize_final_answer",
            session_id=session_id,
            outcome="rewritten",
            details={"reason": "execution-claim"},
        )
        return (
            "I have not executed any change. "
            "This is a read-only investigation summary and recommended next steps.\n\n"
            f"{answer}"
        )

    return answer
