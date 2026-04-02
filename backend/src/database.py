from __future__ import annotations

import json
import os
from datetime import date, datetime
from typing import Any

import asyncpg

_pool: asyncpg.Pool | None = None


async def create_pool() -> None:
    global _pool
    _pool = await asyncpg.create_pool(dsn=os.getenv("DATABASE_URL"), min_size=1, max_size=10)
    await _create_tables()


async def close_pool() -> None:
    if _pool:
        await _pool.close()


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("DB pool not initialized")
    return _pool


async def _create_tables() -> None:
    async with get_pool().acquire() as conn:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS diaries (
                id          SERIAL PRIMARY KEY,
                user_id     INTEGER NOT NULL,
                date        DATE    NOT NULL,
                messages    JSONB   NOT NULL,
                summary     TEXT,
                emotion     TEXT,
                color       TEXT,
                created_at  TIMESTAMPTZ DEFAULT NOW(),
                UNIQUE (user_id, date)
            )
        """)


def _serialize_row(row: asyncpg.Record) -> dict[str, Any]:
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
    date: str,
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
            date,
            json.dumps(messages, ensure_ascii=False),
            summary,
            emotion,
            color,
        )
        return _serialize_row(row)


async def get_diary_by_user_and_date(
    user_id: int,
    date: str,
) -> dict[str, Any] | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM diaries WHERE user_id = $1 AND date = $2",
            user_id,
            date,
        )
        if row is None:
            return None
        return _serialize_row(row)
