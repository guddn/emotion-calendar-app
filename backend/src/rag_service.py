"""Lightweight RAG memory store using Hugging Face sentence-transformers on CPU."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np

try:
    from sentence_transformers import SentenceTransformer
except Exception:  # pragma: no cover - optional dependency at runtime
    SentenceTransformer = None  # type: ignore


@dataclass
class MemoryItem:
    text: str
    metadata: dict[str, Any]
    embedding: np.ndarray


class MemoryRAGStore:
    def __init__(self, model_name: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"):
        self.model_name = model_name
        self._model = self._load_model()
        self._items: list[MemoryItem] = []

    def _load_model(self):
        if SentenceTransformer is None:
            return None
        return SentenceTransformer(self.model_name, device="cpu")

    def _encode(self, text: str) -> np.ndarray:
        if self._model is None:
            # Fallback deterministic vector when model is unavailable.
            values = [ord(c) % 101 for c in text[:64]]
            if not values:
                values = [0]
            vector = np.array(values, dtype=np.float32)
            return vector / np.linalg.norm(vector)

        embedding = self._model.encode(text, normalize_embeddings=True)
        return np.array(embedding, dtype=np.float32)

    def add_memory(self, text: str, metadata: dict[str, Any] | None = None) -> None:
        embedding = self._encode(text)
        self._items.append(MemoryItem(text=text, metadata=metadata or {}, embedding=embedding))

    def retrieve(self, query: str, k: int = 3) -> list[dict[str, Any]]:
        if not self._items:
            return []

        query_embedding = self._encode(query)
        scored: list[tuple[float, MemoryItem]] = []

        for item in self._items:
            min_len = min(len(item.embedding), len(query_embedding))
            if min_len == 0:
                similarity = 0.0
            else:
                similarity = float(np.dot(item.embedding[:min_len], query_embedding[:min_len]))
            scored.append((similarity, item))

        scored.sort(key=lambda x: x[0], reverse=True)
        top_items = scored[:k]
        return [
            {
                "text": item.text,
                "score": score,
                "metadata": item.metadata,
            }
            for score, item in top_items
        ]
