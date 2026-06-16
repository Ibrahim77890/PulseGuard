import json
from collections import defaultdict, deque
from typing import Any

try:
    import redis
except ImportError:  # pragma: no cover - local fallback for environments without optional deps
    redis = None

from app.config import settings


class SessionMemory:
    def append(self, session_id: str, item: dict[str, Any]) -> None:
        raise NotImplementedError

    def read(self, session_id: str) -> list[dict[str, Any]]:
        raise NotImplementedError


class InMemorySessionMemory(SessionMemory):
    def __init__(self, limit: int) -> None:
        self.limit = limit
        self.sessions: dict[str, deque[dict[str, Any]]] = defaultdict(lambda: deque(maxlen=self.limit))

    def append(self, session_id: str, item: dict[str, Any]) -> None:
        self.sessions[session_id].append(item)

    def read(self, session_id: str) -> list[dict[str, Any]]:
        return list(self.sessions[session_id])


class RedisSessionMemory(SessionMemory):
    def __init__(self, host: str, port: int, password: str, limit: int, ttl_seconds: int) -> None:
        if redis is None:
            raise RuntimeError("redis dependency is not installed")
        self.limit = limit
        self.ttl_seconds = ttl_seconds
        self.client = redis.Redis(
            host=host,
            port=port,
            password=password or None,
            decode_responses=True,
        )

    def _key(self, session_id: str) -> str:
        return f"pulseguard:aiops:session:{session_id}"

    def append(self, session_id: str, item: dict[str, Any]) -> None:
        key = self._key(session_id)
        self.client.lpush(key, json.dumps(item))
        self.client.ltrim(key, 0, self.limit - 1)
        self.client.expire(key, self.ttl_seconds)

    def read(self, session_id: str) -> list[dict[str, Any]]:
        payloads = self.client.lrange(self._key(session_id), 0, self.limit - 1)
        return [json.loads(payload) for payload in reversed(payloads)]


def build_session_memory() -> SessionMemory:
    if settings.memory_backend == "redis" and settings.redis_host and redis is not None:
        return RedisSessionMemory(
            host=settings.redis_host,
            port=settings.redis_port,
            password=settings.redis_password,
            limit=settings.session_history_limit,
            ttl_seconds=settings.redis_session_ttl_seconds,
        )
    return InMemorySessionMemory(limit=settings.session_history_limit)
