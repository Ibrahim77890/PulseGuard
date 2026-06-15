from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

from app.agent import AIOpsAssistant
from app.config import settings
from app.memory import build_session_memory
from app.models import AlertTriageRequest, ChatRequest, ChatResponse, SessionSnapshot
from app.tools import ReadOnlyTools


assistant: AIOpsAssistant | None = None
memory = build_session_memory()
tools = ReadOnlyTools()


@asynccontextmanager
async def lifespan(app: FastAPI):
    global assistant
    assistant = AIOpsAssistant(memory=memory, tools=tools)
    yield


app = FastAPI(title="PulseGuard AIOps Assistant", version="0.1.0", lifespan=lifespan)


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "service": settings.service_name}


@app.get("/", response_class=HTMLResponse)
async def home() -> str:
    return """
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>PulseGuard AIOps Assistant</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 2rem; background: #f4f6f8; color: #1f2933; }
      main { max-width: 860px; margin: 0 auto; background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); }
      textarea, input { width: 100%; padding: 0.8rem; margin-top: 0.4rem; margin-bottom: 1rem; }
      button { padding: 0.8rem 1.2rem; background: #0f766e; border: 0; color: white; border-radius: 8px; cursor: pointer; }
      pre { background: #111827; color: #f9fafb; padding: 1rem; border-radius: 8px; white-space: pre-wrap; }
    </style>
  </head>
  <body>
    <main>
      <h1>PulseGuard AIOps Assistant</h1>
      <p>Read-only incident triage across Prometheus, Loki, Grafana, runbooks, and past postmortems.</p>
      <label>Session ID</label>
      <input id="session_id" value="demo-session" />
      <label>Message</label>
      <textarea id="message" rows="6">Investigate the backend latency alert.</textarea>
      <button onclick="send()">Investigate</button>
      <pre id="output">Waiting for a query...</pre>
    </main>
    <script>
      async function send() {
        const payload = {
          session_id: document.getElementById("session_id").value,
          message: document.getElementById("message").value
        };
        const response = await fetch("/chat", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload)
        });
        const data = await response.json();
        document.getElementById("output").textContent = JSON.stringify(data, null, 2);
      }
    </script>
  </body>
</html>
""".strip()


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    assert assistant is not None
    response = await assistant.chat(
        session_id=request.session_id,
        message=request.message,
        routing_mode=request.routing_mode,
        max_tool_rounds=request.max_tool_rounds,
    )
    response.session_id = request.session_id
    return response


@app.post("/triage", response_model=ChatResponse)
async def triage_alert(request: AlertTriageRequest) -> ChatResponse:
    assert assistant is not None
    message = (
        f"Investigate alert {request.alert_name} for service {request.service}. "
        f"Summary: {request.summary}. Signal hint: {request.signal_hint}"
    )
    response = await assistant.chat(
        session_id=request.session_id,
        message=message,
        routing_mode="deep",
        max_tool_rounds=4,
    )
    response.session_id = request.session_id
    return response


@app.get("/sessions/{session_id}", response_model=SessionSnapshot)
async def get_session(session_id: str) -> SessionSnapshot:
    return SessionSnapshot(session_id=session_id, history=memory.read(session_id))
