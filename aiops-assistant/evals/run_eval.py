import asyncio
import json
from pathlib import Path
import time

from app.agent import AIOpsAssistant
from app.memory import InMemorySessionMemory
from app.tools import ReadOnlyTools


DATASET_PATH = Path(__file__).with_name("golden_dataset.json")
RESULTS_PATH = Path(__file__).with_name("latest-results.json")


class FakeTools(ReadOnlyTools):
    async def query_prometheus(self, session_id: str, promql: str) -> dict:
        del session_id, promql
        return {"status": "success", "result_type": "vector", "result": [{"metric": {"service": "backend"}, "value": [0, "1.2"]}]}

    async def query_loki(self, session_id: str, logql: str, limit: int = 20) -> dict:
        del session_id, logql, limit
        return {"status": "success", "result_type": "streams", "result": [{"stream": {"namespace": "backend"}, "values": [["0", "timeout error"]]}]}

    async def fetch_grafana_status(self, session_id: str) -> dict:
        return await super().fetch_grafana_status(session_id)

    async def fetch_runbook(self, session_id: str, runbook_name: str) -> dict:
        return {"title": runbook_name, "source": f"/fake/{runbook_name}", "content": "Runbook content for eval."}

    async def search_incident_memory(self, session_id: str, query: str) -> dict:
        del session_id, query
        return {
            "documents": [
                {
                    "title": "Simulated Incident",
                    "source": "/fake/postmortem.md",
                    "category": "postmortem",
                    "score": 0.9,
                    "excerpt": "Latency increased after dependency slowdown.",
                }
            ]
        }


async def run() -> int:
    dataset = json.loads(DATASET_PATH.read_text(encoding="utf-8"))
    assistant = AIOpsAssistant(memory=InMemorySessionMemory(limit=20), tools=FakeTools())

    tool_score_total = 0.0
    keyword_score_total = 0.0
    total_latency_ms = 0.0

    for index, case in enumerate(dataset):
        started_at = time.perf_counter()
        response = await assistant.chat(
            session_id=f"eval-session-{index}",
            message=case["query"],
            routing_mode="heuristic",
            max_tool_rounds=3,
        )
        elapsed_ms = (time.perf_counter() - started_at) * 1000
        total_latency_ms += elapsed_ms

        actual_tools = set(response.tools_used)
        expected_tools = set(case["expected_tools"])
        matched_tools = len(actual_tools & expected_tools)
        tool_score_total += matched_tools / max(len(expected_tools), 1)

        lowered_answer = response.answer.lower()
        matched_keywords = sum(1 for keyword in case["expected_keywords"] if keyword.lower() in lowered_answer)
        keyword_score_total += matched_keywords / max(len(case["expected_keywords"]), 1)

    case_count = len(dataset)
    results = {
        "cases_run": case_count,
        "quality_score_percent": round((keyword_score_total / case_count) * 100, 2),
        "tool_correctness_percent": round((tool_score_total / case_count) * 100, 2),
        "average_latency_ms": round(total_latency_ms / case_count, 2),
        "average_cost_usd": 0.0,
        "routing_mode": "heuristic",
    }
    RESULTS_PATH.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(json.dumps(results, indent=2))
    if results["quality_score_percent"] < 85 or results["tool_correctness_percent"] < 90:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(run()))
