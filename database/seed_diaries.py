"""
diaries 테이블 seed 스크립트
output_daily_*.json → diaries

실행: python seed_diaries.py
의존: pip install asyncpg python-dotenv
"""
import asyncio
import json
import os
import sys
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

# ── 설정 ─────────────────────────────────────────────────────────────────────
LIMIT      = 60            # 삽입할 일기 최대 개수 (파일 3개 합산 기준)
GROUP_SIZE = 10            # 몇 개 대화마다 user_id를 1씩 증가시킬지
END_DATE   = date.today()  # 가장 최근 일기 날짜 → 오늘부터 역산
# ─────────────────────────────────────────────────────────────────────────────

BASE_DIR   = Path(__file__).parent
ENV_PATH   = BASE_DIR.parent / "backend" / ".env"
DATA_FILES = [
    BASE_DIR / "output_ daily_1st.json",
    BASE_DIR / "output_daily_2nd.json",
    BASE_DIR / "output_daily_3rd.json",
]


def load_conversations() -> list[list[dict]]:
    """3개 파일에서 index 기준 대화 그룹을 순서대로 수집."""
    all_convs: list[list[dict]] = []
    for path in DATA_FILES:
        if not path.exists():
            print(f"[경고] 파일 없음: {path.name}")
            continue
        with open(path, encoding="utf-8") as f:
            rows = json.load(f)
        groups: dict[int, list[dict]] = defaultdict(list)
        for row in rows:
            groups[row["index"]].append(row)
        for idx in sorted(groups):
            all_convs.append(groups[idx])
    return all_convs


def to_messages(turns: list[dict]) -> list[dict]:
    """[{user_utterance, system_utterance}] → [{role, content}]"""
    messages: list[dict] = []
    for turn in turns:
        user   = turn.get("user_utterance", "")
        system = turn.get("system_utterance", "")
        if user and user != "null":
            messages.append({"role": "user", "content": user})
        if system:
            messages.append({"role": "assistant", "content": system})
    return messages


async def ensure_users(conn: asyncpg.Connection, max_user_id: int) -> None:
    """seed용 유저가 없으면 자동 생성 (FK 제약 충족)."""
    # 기존 데이터로 인해 시퀀스가 어긋난 경우 동기화
    await conn.execute(
        "SELECT setval(pg_get_serial_sequence('users', 'id'), "
        "(SELECT COALESCE(MAX(id), 0) FROM users), true)"
    )
    for uid in range(1, max_user_id + 1):
        await conn.execute(
            """
            INSERT INTO users (auth_provider_id, email, nickname)
            VALUES ($1, $2, $3)
            ON CONFLICT (auth_provider_id) DO NOTHING
            """,
            f"seed_{uid}",
            f"seed{uid}@example.com",
            f"테스트유저{uid}",
        )


async def seed() -> None:
    load_dotenv(ENV_PATH)
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        sys.exit("❌  DATABASE_URL 환경변수가 없습니다. backend/.env 를 확인하세요.")

    conversations = load_conversations()[:LIMIT]
    total = len(conversations)
    max_user_id = (total - 1) // GROUP_SIZE + 1
    print(f"📝  삽입 예정: {total}개 일기 (user_id 1~{max_user_id}, {GROUP_SIZE}개씩 그룹)")

    conn = await asyncpg.connect(dsn=dsn)
    try:
        await ensure_users(conn, max_user_id)

        inserted = skipped = 0
        for i, turns in enumerate(conversations):
            user_id    = (i // GROUP_SIZE) + 1
            entry_date = END_DATE - timedelta(days=total - 1 - i)
            messages   = to_messages(turns)
            if not messages:
                skipped += 1
                continue
            try:
                await conn.execute(
                    """
                    INSERT INTO diaries (user_id, date, messages)
                    VALUES ($1, $2, $3::jsonb)
                    ON CONFLICT (user_id, date) DO NOTHING
                    """,
                    user_id,
                    entry_date,
                    json.dumps(messages, ensure_ascii=False),
                )
                inserted += 1
                if inserted % 10 == 0:
                    print(f"  진행: {inserted}개 완료 (최근 user_id={user_id})")
            except Exception as e:
                print(f"  [건너뜀] i={i}, user_id={user_id}, date={entry_date}: {e}")
                skipped += 1
    finally:
        await conn.close()

    print(f"✅  완료 — 삽입: {inserted}개, 건너뜀: {skipped}개")


if __name__ == "__main__":
    asyncio.run(seed())
