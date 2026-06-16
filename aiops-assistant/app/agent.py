import json
from typing import Any

import httpx

from app.config import settings
from app.knowledge import search_knowledge
from app.memory import SessionMemory
from app.models import ChatResponse, RetrievedDocument
from app.observability import TimedOperation, estimate_llm_cost, get_tracer, observe_llm_usage
from app.tools import ReadOnlyTools, TOOL_DEFINITIONS


SYSTEM_PROMPT = """
You are the PulseGuard AIOps Assistant.
Your job is to investigate alerts using only read-only tools.
Prefer evidence over guesses. Cite dashboards, runbooks, and past incidents when possible.
Never claim you executed a change. You diagnose and recommend next steps only.
Return a concise triage summary with:
1. likely problem
2. evidence gathered
3. confidence
4. next steps
""".strip()


class AIOpsAssistant:
    def __init__(self, memory: SessionMemory, tools: ReadOnlyTools) -> None:
        self.memory = memory
        self.tools = tools
        self.tracer = get_tracer()

    async def chat(self, session_id: str, message: str, routing_mode: str, max_tool_rounds: int) -> ChatResponse:
        model = settings.selected_model(routing_mode, message)
        with self.tracer.start_as_current_span("aiops.chat") as span:
            span.set_attribute("gen_ai.system", "openrouter" if settings.openrouter_api_key else "heuristic")
            span.set_attribute("gen_ai.request.model", model)
            span.set_attribute("aiops.session_id", session_id)
            span.set_attribute("aiops.routing_mode", routing_mode)

            history = self._history_for_llm(session_id)
            dashboard_links = await self.tools.fetch_grafana_status(session_id)

            if not settings.openrouter_api_key or routing_mode == "heuristic":
                response = await self._heuristic_response(session_id, message, model, dashboard_links["dashboards"])
                self._remember(session_id, message, response.answer)
                return response

            messages: list[dict[str, Any]] = [{"role": "system", "content": SYSTEM_PROMPT}]
            messages.extend(history)
            messages.append({"role": "user", "content": message})

            retrieved_documents: list[RetrievedDocument] = []
            tools_used: list[str] = []

            async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
                for round_index in range(max_tool_rounds):
                    with self.tracer.start_as_current_span("aiops.reasoning_step") as step_span:
                        step_span.set_attribute("aiops.round_index", round_index)
                        payload = {
                            "model": model,
                            "messages": messages,
                            "tools": TOOL_DEFINITIONS,
                            "tool_choice": "auto",
                        }
                        timer = TimedOperation()
                        response = await client.post(
                            f"{settings.openrouter_base_url.rstrip('/')}/chat/completions",
                            headers={
                                "Authorization": f"Bearer {settings.openrouter_api_key}",
                                "Content-Type": "application/json",
                            },
                            json=payload,
                        )
                        response.raise_for_status()
                        llm_payload = response.json()
                        assistant_message = llm_payload["choices"][0]["message"]
                        tool_calls = assistant_message.get("tool_calls") or []
                        usage = llm_payload.get("usage", {})
                        input_tokens = int(usage.get("prompt_tokens", 0))
                        output_tokens = int(usage.get("completion_tokens", 0))
                        finish_reason = llm_payload["choices"][0].get("finish_reason", "unknown")
                        cost_usd = estimate_llm_cost(model, input_tokens, output_tokens)
                        observe_llm_usage(model, input_tokens, output_tokens, cost_usd)
                        step_span.set_attribute("gen_ai.usage.input_tokens", input_tokens)
                        step_span.set_attribute("gen_ai.usage.output_tokens", output_tokens)
                        step_span.set_attribute("gen_ai.response.finish_reason", finish_reason)
                        step_span.set_attribute("aiops.llm_cost_usd", cost_usd)
                        step_span.set_attribute("aiops.reasoning_duration_seconds", timer.elapsed)

                        messages.append(
                            {
                                "role": "assistant",
                                "content": assistant_message.get("content", ""),
                                "tool_calls": tool_calls,
                            }
                        )

                        if not tool_calls:
                            answer = assistant_message.get("content", "").strip()
                            chat_response = ChatResponse(
                                session_id=session_id,
                                model=model,
                                answer=answer,
                                confidence=self._derive_confidence(tools_used, retrieved_documents),
                                tools_used=tools_used,
                                retrieved_documents=retrieved_documents,
                                dashboard_links=dashboard_links["dashboards"],
                            )
                            self._remember(session_id, message, answer)
                            return chat_response

                        for tool_call in tool_calls:
                            function_name = tool_call["function"]["name"]
                            function_args = json.loads(tool_call["function"]["arguments"] or "{}")
                            result = await self._execute_tool(function_name, session_id, function_args)
                            tools_used.append(function_name)
                            self.memory.append(
                                session_id,
                                {
                                    "role": "tool",
                                    "name": function_name,
                                    "content": json.dumps(result)[:4000],
                                },
                            )

                            if function_name == "search_incident_memory":
                                retrieved_documents.extend(
                                    RetrievedDocument(
                                        title=document["title"],
                                        source=document["source"],
                                        category=document["category"],
                                        score=document["score"],
                                    )
                                    for document in result.get("documents", [])
                                )

                            messages.append(
                                {
                                    "role": "tool",
                                    "tool_call_id": tool_call["id"],
                                    "name": function_name,
                                    "content": json.dumps(result),
                                }
                            )

            fallback = await self._heuristic_response(session_id, message, model, dashboard_links["dashboards"])
            self._remember(session_id, message, fallback.answer)
            return fallback

    async def _execute_tool(self, name: str, session_id: str, args: dict[str, Any]) -> dict[str, Any]:
        if name == "query_prometheus":
            return await self.tools.query_prometheus(session_id, promql=args["promql"])
        if name == "query_loki":
            return await self.tools.query_loki(session_id, logql=args["logql"], limit=args.get("limit", 20))
        if name == "fetch_grafana_status":
            return await self.tools.fetch_grafana_status(session_id)
        if name == "fetch_runbook":
            return await self.tools.fetch_runbook(session_id, runbook_name=args["runbook_name"])
        if name == "search_incident_memory":
            return await self.tools.search_incident_memory(session_id, query=args["query"])
        raise ValueError(f"Unsupported tool: {name}")

    def _fallback_response(
        self,
        session_id: str,
        message: str,
        model: str,
        dashboard_links: dict[str, str],
    ) -> ChatResponse:
        matches = search_knowledge(message, limit=3)
        retrieved_documents = [
            RetrievedDocument(
                title=document.title,
                source=document.source,
                category=document.category,
                score=round(score, 4),
            )
            for document, score in matches
        ]
        evidence_lines = [
            f"- {document.title} ({document.category})"
            for document in retrieved_documents
        ]
        answer = (
            "OpenRouter is not configured, so I returned a repo-backed first-pass triage summary.\n\n"
            "Likely problem:\n"
            f"{message}\n\n"
            "Evidence gathered:\n"
            f"{chr(10).join(evidence_lines) if evidence_lines else '- No matching runbook or postmortem found.'}\n\n"
            "Next steps:\n"
            f"- Start with the error budget dashboard: {dashboard_links['error_budget']}\n"
            f"- Check service RED metrics: {dashboard_links['red']}\n"
            f"- Review recent logs and traces before escalating.\n"
        )
        return ChatResponse(
            session_id=session_id,
            model=model,
            answer=answer,
            confidence=self._derive_confidence([], retrieved_documents),
            tools_used=["search_incident_memory"],
            retrieved_documents=retrieved_documents,
            dashboard_links=dashboard_links,
        )

    async def _heuristic_response(
        self,
        session_id: str,
        message: str,
        model: str,
        dashboard_links: dict[str, str],
    ) -> ChatResponse:
        tools_used: list[str] = []
        evidence_lines: list[str] = []
        retrieved_documents: list[RetrievedDocument] = []

        with self.tracer.start_as_current_span("aiops.heuristic_investigation") as span:
            span.set_attribute("gen_ai.system", "heuristic")
            span.set_attribute("gen_ai.request.model", model)

            grafana = await self.tools.fetch_grafana_status(session_id)
            tools_used.append("fetch_grafana_status")
            evidence_lines.append(f"- Dashboard entrypoint: {grafana['recommended_start']}")

            lower_message = message.lower()
            if any(keyword in lower_message for keyword in ["latency", "slow", "duration", "burn", "error budget", "5xx", "availability"]):
                promql = (
                    "slo:availability_burn_rate_1h or slo:availability_burn_rate_6h or "
                    "histogram_quantile(0.95, sum by (le, service) (rate(http_server_requests_seconds_bucket[5m]))) * 1000"
                )
                prometheus_result = await self.tools.query_prometheus(session_id, promql)
                tools_used.append("query_prometheus")
                evidence_lines.append(f"- Prometheus returned {len(prometheus_result.get('result', []))} series for burn-rate and latency checks.")

            if any(keyword in lower_message for keyword in ["log", "error", "latency", "timeout", "investigate", "alert"]):
                loki_result = await self.tools.query_loki(session_id, '{namespace=~"frontend|backend|data"} |= "error"', limit=10)
                tools_used.append("query_loki")
                evidence_lines.append(f"- Loki returned {len(loki_result.get('result', []))} recent log streams.")

            memory_result = await self.tools.search_incident_memory(session_id, message)
            tools_used.append("search_incident_memory")
            retrieved_documents = [
                RetrievedDocument(
                    title=document["title"],
                    source=document["source"],
                    category=document["category"],
                    score=document["score"],
                )
                for document in memory_result.get("documents", [])
            ]
            for document in retrieved_documents:
                evidence_lines.append(f"- Similar {document.category}: {document.title}")

            runbook_name = self._guess_runbook_name(message)
            if runbook_name:
                try:
                    runbook = await self.tools.fetch_runbook(session_id, runbook_name)
                    tools_used.append("fetch_runbook")
                    evidence_lines.append(f"- Matched runbook: {runbook['title']}")
                except FileNotFoundError:
                    pass

            answer = (
                "OpenRouter is not configured, so this is a deterministic first-pass investigation using read-only PulseGuard tools.\n\n"
                "Likely problem:\n"
                f"{message}\n\n"
                "Evidence gathered:\n"
                f"{chr(10).join(evidence_lines) if evidence_lines else '- No supporting evidence collected.'}\n\n"
                "Next steps:\n"
                f"- Review the error budget dashboard: {dashboard_links['error_budget']}\n"
                f"- Check service RED metrics: {dashboard_links['red']}\n"
                f"- Correlate with recent logs and traces before escalating.\n"
            )
            return ChatResponse(
                session_id=session_id,
                model=model,
                answer=answer,
                confidence=self._derive_confidence(tools_used, retrieved_documents),
                tools_used=tools_used,
                retrieved_documents=retrieved_documents,
                dashboard_links=dashboard_links,
            )

    def _derive_confidence(self, tools_used: list[str], retrieved_documents: list[RetrievedDocument]) -> str:
        if len(tools_used) >= 2 and retrieved_documents:
            return "high"
        if tools_used or retrieved_documents:
            return "medium"
        return "low"

    def _remember(self, session_id: str, user_message: str, assistant_message: str) -> None:
        self.memory.append(session_id, {"role": "user", "content": user_message})
        self.memory.append(session_id, {"role": "assistant", "content": assistant_message})

    def _history_for_llm(self, session_id: str) -> list[dict[str, Any]]:
        history: list[dict[str, Any]] = []
        for item in self.memory.read(session_id):
            role = item.get("role")
            if role in {"user", "assistant"}:
                history.append({"role": role, "content": item.get("content", "")})
            elif role == "tool":
                history.append(
                    {
                        "role": "assistant",
                        "content": f"Previous tool result from {item.get('name', 'tool')}: {item.get('content', '')}",
                    }
                )
        return history

    def _guess_runbook_name(self, message: str) -> str | None:
        lower_message = message.lower()
        if "fast burn" in lower_message:
            return "slo-fast-burn.md"
        if "slow burn" in lower_message or "latency" in lower_message:
            return "slo-slow-burn.md"
        if "budget below" in lower_message:
            return "slo-budget-below-ten-percent.md"
        if "warning" in lower_message:
            return "slo-warning-budget-risk.md"
        if "critical" in lower_message:
            return "slo-critical-budget-risk.md"
        return None
