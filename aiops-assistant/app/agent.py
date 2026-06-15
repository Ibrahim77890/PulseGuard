import json
from typing import Any

import httpx

from app.config import settings
from app.knowledge import search_knowledge
from app.memory import SessionMemory
from app.models import ChatResponse, RetrievedDocument
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

    async def chat(self, session_id: str, message: str, routing_mode: str, max_tool_rounds: int) -> ChatResponse:
        model = settings.selected_model(routing_mode, message)
        history = self.memory.read(session_id)
        dashboard_links = await self.tools.fetch_grafana_status(session_id)

        if not settings.openrouter_api_key:
            response = self._fallback_response(session_id, message, model, dashboard_links["dashboards"])
            self._remember(session_id, message, response.answer)
            return response

        messages: list[dict[str, Any]] = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.extend(history)
        messages.append({"role": "user", "content": message})

        retrieved_documents: list[RetrievedDocument] = []
        tools_used: list[str] = []

        async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
            for _ in range(max_tool_rounds):
                payload = {
                    "model": model,
                    "messages": messages,
                    "tools": TOOL_DEFINITIONS,
                    "tool_choice": "auto",
                }
                response = await client.post(
                    f"{settings.openrouter_base_url.rstrip('/')}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.openrouter_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )
                response.raise_for_status()
                assistant_message = response.json()["choices"][0]["message"]
                tool_calls = assistant_message.get("tool_calls") or []

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

        fallback = self._fallback_response(session_id, message, model, dashboard_links["dashboards"])
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
        del session_id
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

    def _derive_confidence(self, tools_used: list[str], retrieved_documents: list[RetrievedDocument]) -> str:
        if len(tools_used) >= 2 and retrieved_documents:
            return "high"
        if tools_used or retrieved_documents:
            return "medium"
        return "low"

    def _remember(self, session_id: str, user_message: str, assistant_message: str) -> None:
        self.memory.append(session_id, {"role": "user", "content": user_message})
        self.memory.append(session_id, {"role": "assistant", "content": assistant_message})
