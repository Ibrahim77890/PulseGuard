import base64
import json
import logging
from typing import Any


def _decode_payload(event: dict[str, Any]) -> dict[str, Any]:
    raw = event.get("data", "")
    if not raw:
        return {}
    decoded = base64.b64decode(raw).decode("utf-8")
    try:
        return json.loads(decoded)
    except json.JSONDecodeError:
        return {"message": decoded}


def handle_pubsub(event: dict[str, Any], context: Any) -> None:
    payload = _decode_payload(event)
    attributes = event.get("attributes", {})

    log_entry = {
      "category": "runtime-security",
      "source": "falco",
      "message_id": getattr(context, "event_id", None),
      "publish_time": getattr(context, "timestamp", None),
      "attributes": attributes,
      "payload": payload,
    }

    logging.warning(json.dumps(log_entry))
