from __future__ import annotations

from typing import Any

from src.database import get_pool


async def create_user(
    auth_provider_id: str,
    email: str | None = None,
    nickname: str | None = None,
) -> dict[str, Any]:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            """
            INSERT INTO users (auth_provider_id, email, nickname)
            VALUES ($1, $2, $3)
            ON CONFLICT (auth_provider_id) DO UPDATE SET
                email    = EXCLUDED.email,
                nickname = EXCLUDED.nickname
            RETURNING *
            """,
            auth_provider_id,
            email,
            nickname,
        )
        return dict(row)


async def get_user_by_id(user_id: int) -> dict[str, Any] | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
        return dict(row) if row else None


async def get_user_by_provider_id(auth_provider_id: str) -> dict[str, Any] | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM users WHERE auth_provider_id = $1", auth_provider_id
        )
        return dict(row) if row else None
