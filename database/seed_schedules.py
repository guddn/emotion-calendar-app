"""
schedules 테이블 seed 스크립트
output_task.json → schedules

각 index 그룹(회의 대화)에서 제목·시각·장소를 추출해 삽입합니다.

실행: python seed_schedules.py
의존: pip install asyncpg python-dotenv
"""
import asyncio
import json
import os
import re
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

# ── 설정 ──────────────────────────────────────────────────────────────────────
LIMIT      = 30             # 삽입할 일정 최대 개수
GROUP_SIZE = 10             # 몇 개 일정마다 user_id를 1씩 증가시킬지
START_DATE = date.today()   # 첫 번째 일정 날짜 (오늘부터 하루씩 간격으로 분산)
# ─────────────────────────────────────────────────────────────────────────────

BASE_DIR  = Path(__file__).parent
ENV_PATH  = BASE_DIR.parent / "backend" / ".env"
TASK_FILE = BASE_DIR / "output_task.json"

# 정규식 패턴
_TIME_RE    = re.compile(r'(오전|오후)\s*(\d+)시')
_TITLE_RE   = re.compile(r'에서\s+(.+?)\s*(?:관련\s+)?(?:팀회의|회의|미팅|세미나)(?:가|이)')
_PLACE_RE   = re.compile(r'(.+?(?:센터|실|관|홀|장|room))\s*에서')


def extract_info(turns: list[dict]) -> dict | None:
    """대화 그룹에서 제목·시간·장소를 추출. 추출 실패 시 None."""
    title = hour = place = None

    for turn in turns:
        text = turn.get("system_utterance") or ""

        if title is None:
            m = _TITLE_RE.search(text)
            if m:
                title = m.group(1).strip() + " 회의"

        if hour is None:
            m = _TIME_RE.search(text)
            if m:
                ampm  = m.group(1)
                h     = int(m.group(2))
                hour  = h + 12 if ampm == "오후" and h != 12 else h

        if place is None:
            m = _PLACE_RE.search(text)
            if m:
                place = m.group(1).strip()

    if title is None:
        return None

    return {
        "title":       title,
        "description": place,
        "hour":        hour if hour is not None else 10,
    }


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

    if not TASK_FILE.exists():
        sys.exit(f"❌  파일 없음: {TASK_FILE}")

    with open(TASK_FILE, encoding="utf-8") as f:
        rows = json.load(f)

    groups: dict[int, list[dict]] = defaultdict(list)
    for row in rows:
        groups[row["index"]].append(row)

    schedules: list[dict] = []
    for idx in sorted(groups):
        info = extract_info(groups[idx])
        if info:
            schedules.append(info)
        if len(schedules) >= LIMIT:
            break

    total = len(schedules)
    max_user_id = (total - 1) // GROUP_SIZE + 1
    print(f"📅  삽입 예정: {total}개 일정 (user_id 1~{max_user_id}, {GROUP_SIZE}개씩 그룹)")

    conn = await asyncpg.connect(dsn=dsn)
    try:
        await ensure_users(conn, max_user_id)

        inserted = skipped = 0
        for i, s in enumerate(schedules):
            user_id    = (i // GROUP_SIZE) + 1
            sched_date = START_DATE + timedelta(days=i)
            sched_dt   = datetime(
                sched_date.year, sched_date.month, sched_date.day,
                s["hour"], 0, 0,
            )
            try:
                await conn.execute(
                    """
                    INSERT INTO schedules (user_id, title, description, scheduled_at)
                    VALUES ($1, $2, $3, $4)
                    """,
                    user_id,
                    s["title"],
                    s["description"],
                    sched_dt,
                )
                inserted += 1
                if inserted % 10 == 0:
                    print(f"  진행: {inserted}개 완료 (최근 user_id={user_id})")
            except Exception as e:
                print(f"  [오류] '{s['title']}' (user_id={user_id}): {e}")
                skipped += 1
    finally:
        await conn.close()

    print(f"✅  완료 — 삽입: {inserted}개, 건너뜀: {skipped}개")


if __name__ == "__main__":
    asyncio.run(seed())
