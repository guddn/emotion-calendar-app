from __future__ import annotations

from typing import Any

from src.database import get_pool


async def get_current_streak(user_id: int) -> int:
    """특정 사용자의 현재 연속 작성 일수를 반환합니다."""
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            """
            WITH diary_groups AS (
                SELECT
                    date,
                    date - (ROW_NUMBER() OVER (ORDER BY date))::int AS grp
                FROM diaries
                WHERE user_id = $1
            )
            SELECT COUNT(*) AS current_streak
            FROM diary_groups
            GROUP BY grp
            HAVING MAX(date) >= CURRENT_DATE - INTERVAL '1 day'
            ORDER BY MAX(date) DESC
            LIMIT 1
            """,
            user_id,
        )
        return int(row["current_streak"]) if row else 0


async def get_emotion_stats(user_id: int) -> list[dict[str, Any]]:
    """사용자가 느낀 감정별 빈도수와 비율을 내림차순으로 반환합니다."""
    async with get_pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT
                emotion,
                color,
                COUNT(*) AS frequency,
                ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
            FROM diaries
            WHERE user_id = $1
            GROUP BY emotion, color
            ORDER BY frequency DESC
            """,
            user_id,
        )
        return [dict(row) for row in rows]
