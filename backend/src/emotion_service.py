"""Emotion parsing and color mapping utilities."""

from __future__ import annotations

import json
from typing import Any

EMOTION_COLORS: dict[str, str] = {
    "분노": "#FF4500",
    "기대": "#FFA500",
    "기쁨": "#FFFF00",
    "신뢰": "#7FFF00",
    "공포": "#00FF00",
    "놀람": "#00FFFF",
    "슬픔": "#0000FF",
    "혐오": "#800080",
    "중립": "#FFFFFF",
}

EMOTION_ALIASES: dict[str, str] = {
    "angry": "분노",
    "anger": "분노",
    "anticipation": "기대",
    "expectation": "기대",
    "happy": "기쁨",
    "joy": "기쁨",
    "trust": "신뢰",
    "fear": "공포",
    "surprise": "놀람",
    "sad": "슬픔",
    "sadness": "슬픔",
    "disgust": "혐오",
    "neutral": "중립",
    "tired": "중립",
}


def _normalize_emotion_name(raw: str) -> str:
    value = raw.strip()
    if value in EMOTION_COLORS:
        return value
    lowered = value.lower()
    return EMOTION_ALIASES.get(lowered, "중립")


def parse_emotion_payload(payload: str | dict[str, Any]) -> str:
    """Parse emotion payload from LLM output and return dominant emotion label in Korean."""
    if isinstance(payload, dict):
        if not payload:
            return "중립"
        dominant = max(payload.items(), key=lambda item: float(item[1]))[0]
        return _normalize_emotion_name(str(dominant))

    data = payload.strip()
    if not data:
        return "중립"

    if data.startswith("{"):
        try:
            parsed = json.loads(data)
            if isinstance(parsed, dict):
                return parse_emotion_payload(parsed)
        except json.JSONDecodeError:
            pass

    return _normalize_emotion_name(data)


def extract_emotion_tag(text: str) -> tuple[str, str]:
    """Extract [EMOTION:...] tag from assistant text and return (clean_text, emotion)."""
    marker = "[EMOTION:"
    if marker not in text:
        return text.strip(), "중립"

    start = text.find(marker)
    end = text.find("]", start)
    if end == -1:
        return text.strip(), "중립"

    payload = text[start + len(marker) : end]
    clean_text = (text[:start] + text[end + 1 :]).strip()
    return clean_text, parse_emotion_payload(payload)


def emotion_to_color(emotion: str) -> str:
    return EMOTION_COLORS.get(_normalize_emotion_name(emotion), EMOTION_COLORS["중립"])
