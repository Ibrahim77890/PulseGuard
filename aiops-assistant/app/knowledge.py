from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import re

from app.config import settings


TOKEN_PATTERN = re.compile(r"[a-zA-Z0-9_-]{3,}")


@dataclass
class KnowledgeDocument:
    title: str
    source: str
    category: str
    content: str
    tokens: set[str]


def _tokenize(text: str) -> set[str]:
    return {token.lower() for token in TOKEN_PATTERN.findall(text)}


def _load_markdown_documents(root: Path, category: str) -> list[KnowledgeDocument]:
    documents: list[KnowledgeDocument] = []
    if not root.exists():
        return documents

    for path in sorted(root.glob("*.md")):
        content = path.read_text(encoding="utf-8")
        title = content.splitlines()[0].lstrip("# ").strip() if content else path.stem
        documents.append(
            KnowledgeDocument(
                title=title,
                source=str(path),
                category=category,
                content=content,
                tokens=_tokenize(f"{title}\n{content}"),
            )
        )
    return documents


@lru_cache(maxsize=1)
def load_knowledge_base() -> list[KnowledgeDocument]:
    runbooks = _load_markdown_documents(Path(settings.runbooks_root), "runbook")
    postmortems = _load_markdown_documents(Path(settings.postmortems_root), "postmortem")
    return runbooks + postmortems


def search_knowledge(query: str, limit: int = 3) -> list[tuple[KnowledgeDocument, float]]:
    query_tokens = _tokenize(query)
    results: list[tuple[KnowledgeDocument, float]] = []

    for document in load_knowledge_base():
        overlap = len(query_tokens & document.tokens)
        if overlap == 0:
            continue
        score = overlap / max(len(query_tokens), 1)
        results.append((document, score))

    results.sort(key=lambda item: item[1], reverse=True)
    return results[:limit]
