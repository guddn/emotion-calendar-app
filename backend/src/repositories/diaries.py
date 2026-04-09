from __future__ import annotations

import json
from datetime import date, datetime
from typing import Any

from src.database import get_pool


def _serialize_row(row: Any) -> dict[str, Any]:
    d = dict(row)
    if isinstance(d.get("messages"), str):
        d["messages"] = json.loads(d["messages"])
    if isinstance(d.get("date"), date):
        d["date"] = d["date"].isoformat()
    if isinstance(d.get("created_at"), datetime):
        d["created_at"] = d["created_at"].isoformat()
    return d


async def save_diary(
    user_id: int,
    date_str: str,
    messages: list[dict],
    summary: str | None,
    emotion: str | None,
    color: str | None,
) -> dict[str, Any]:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO diaries (user_id, date, messages, summary, emotion, color)
            VALUES ($1, $2, $3::jsonb, $4, $5, $6)
            ON CONFLICT (user_id, date) DO UPDATE SET
                messages   = EXCLUDED.messages,
                summary    = EXCLUDED.summary,
                emotion    = EXCLUDED.emotion,
                color      = EXCLUDED.color,
                created_at = NOW()
            RETURNING *
            """,
            user_id,
            date.fromisoformat(date_str) if isinstance(date_str, str) else date_str,
            json.dumps(messages, ensure_ascii=False),
            summary,
            emotion,
            color,
        )
        return _serialize_row(row)


async def get_diary_by_user_and_date(
    user_id: int,
    date_str: str,
) -> dict[str, Any] | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM diaries WHERE user_id = $1 AND date = $2",
            user_id,
            date.fromisoformat(date_str) if isinstance(date_str, str) else date_str,
        )
        return _serialize_row(row) if row else None
