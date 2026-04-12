from __future__ import annotations

import os

import asyncpg

_pool: asyncpg.Pool | None = None


async def create_pool() -> None:
    global _pool
    _pool = await asyncpg.create_pool(dsn=os.getenv("DATABASE_URL"), min_size=1, max_size=10, statement_cache_size=0)


async def close_pool() -> None:
    if _pool:
        await _pool.close()


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("DB pool not initialized")
    return _pool
