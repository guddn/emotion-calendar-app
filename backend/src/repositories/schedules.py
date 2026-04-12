from __future__ import annotations

from datetime import date, datetime
from typing import Any

from src.database import get_pool


async def create_schedule(
    user_id: int,
    title: str,
    scheduled_at: date,
    description: str | None = None,
) -> dict[str, Any]:
    
    if isinstance(scheduled_at, str):
        # 문자열로 들어왔다면 date 객체로 변환
        scheduled_at = datetime.strptime(scheduled_at, "%Y-%m-%d").date()

    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO schedules (user_id, title, description, scheduled_at)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            """,
            user_id,
            title,
            description,
            scheduled_at,
        )
        return dict(row)


async def get_schedules_by_user(user_id: int) -> list[dict[str, Any]]:
    async with get_pool().acquire() as conn:
        rows = await conn.fetch(
            "SELECT * FROM schedules WHERE user_id = $1 ORDER BY scheduled_at",
            user_id,
        )
        return [dict(row) for row in rows]


async def mark_done(schedule_id: int) -> dict[str, Any] | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            "UPDATE schedules SET is_done = TRUE WHERE id = $1 RETURNING *",
            schedule_id,
        )
        return dict(row) if row else None
