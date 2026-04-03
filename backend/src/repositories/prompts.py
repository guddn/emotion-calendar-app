from __future__ import annotations

from typing import Any

from src.database import get_pool


async def create_prompt(
    user_id: int,
    date: str,
    content: str,
    basis_schedule_id: int | None = None,
) -> dict[str, Any]:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO prompts (user_id, date, content, basis_schedule_id)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            """,
            user_id,
            date,
            content,
            basis_schedule_id,
        )
        return dict(row)


async def get_prompts_by_user_and_date(
    user_id: int,
    date: str,
) -> list[dict[str, Any]]:
    async with get_pool().acquire() as conn:
        rows = await conn.fetch(
            "SELECT * FROM prompts WHERE user_id = $1 AND date = $2 ORDER BY created_at",
            user_id,
            date,
        )
        return [dict(row) for row in rows]
