1. 프로젝트 구조
┌─────────────────────────────────────────────────────────────────────────┐
│                   Flutter App (Frontend)                                │
│                                                                         │
│  main.dart                                                              │
│  └── RootPage                                                           │
│       ├── MainChatScreen (character_screen.dart)                        │
│       │    └── ChatScreen (chat_screen.dart)                            │
│       │         ├── POST /chat        → 대화 응답 (retrieval 이용)        │
│       │         └── POST /daily-summary → 하루 요약                      │
│       │                                                                 │
│       └── CalendarScreen (calendar_screen.dart)                         │
│            └── _openDailySummary(date)                                  │
│                 └── GET /diary?user_id&date                             │
│                      └── CalendarDailySummaryDialog                     │
│                           ├── _DiarySummaryCard  (있을때)                │
│                           └── _EmptyDiaryCard    (없을때)                │
│                                                                         │
│  lib/data/                                                              │
│  ├── diary.dart            → DiaryModel                                 │
│  └── diary_api_service.dart → DiaryApiService                           │
└─────────────────┬───────────────────────────────────────────────────────┘
                  │ HTTPS
                  ▼
┌─────────────────────────────────────────────────────────┐
│           FastAPI Backend (Hugging Face Spaces)         │
│                                                         │
│  app.py                                                 │
│  ├── GET  /                                             │
│  ├── POST /chat          → GPT + RAG → ChatResponse     │
│  ├── POST /analyze-emotion → 감정 분석                   │
│  ├── POST /daily-summary → GPT 요약                     │
│  ├── POST /diary         → 일기 저장                     │
│  └── GET  /diary         → 일기 조회                     │
│                                                         │
│  src/                                                   │
│  ├── database.py         → asyncpg 커넥션 풀             │
│  ├── emotion_service.py  → 감정/색상 변환                 │
│  ├── prompts.py          → GPT 시스템 프롬프트            │
│  └── rag_service.py      → 메모리 RAG (현재는 휘발성)      │
└─────────────────┬───────────────────────────────────────┘
                  │ asyncpg (PostgreSQL wire protocol)
                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          Supabase (PostgreSQL)                         │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ users                                                            │  │
│  ├───────────────────┬──────────────┬─────────────────────────────┤  │
│  │ id                │ INT          │ PK · 자동 증가                │  │
│  │ auth_provider_id  │ TEXT         │ UNIQUE · 소셜 로그인 고유 ID   │  │
│  │ email             │ TEXT         │ 이메일                        │  │
│  │ nickname          │ TEXT         │ 닉네임                        │  │
│  │ created_at        │ TIMESTAMPTZ  │ 생성 시각                     │  │
│  └───────────────────┴──────────────┴─────────────────────────────┘  │
│         │ 1                      │ 1                      │ 1         │
│       owns                   manages                  receives        │
│         │ 0..*                   │ 0..*                   │ 0..*      │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ diaries                                                          │  │
│  ├───────────────────┬──────────────┬─────────────────────────────┤  │
│  │ id                │ INT          │ PK · 자동 증가                │  │
│  │ user_id           │ INT          │ FK → users.id                │  │
│  │ date              │ DATE         │ 일기 날짜                     │  │
│  │ messages          │ JSONB        │ 대화 내역 [{role, content}]   │  │
│  │ summary           │ TEXT         │ GPT 요약                      │  │
│  │ emotion           │ VARCHAR(20)  │ 대표 감정 (기쁨 등)            │  │
│  │ color             │ VARCHAR(7)   │ 감정 색상 (#FFFF00)           │  │
│  │ created_at        │ TIMESTAMPTZ  │ 저장 시각                     │  │
│  ├───────────────────┴──────────────┴─────────────────────────────┤  │
│  │ UNIQUE (user_id, date)                                           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ schedules                                                        │  │
│  ├───────────────────┬──────────────┬─────────────────────────────┤  │
│  │ id                │ INT          │ PK · 자동 증가                │  │
│  │ user_id           │ INT          │ FK → users.id                │  │
│  │ title             │ TEXT         │ 일정 제목                     │  │
│  │ description       │ TEXT         │ 일정 설명                     │  │
│  │ scheduled_at      │ TIMESTAMPTZ  │ 일정 시각                     │  │
│  │ is_done           │ BOOLEAN      │ 완료 여부                     │  │
│  │ created_at        │ TIMESTAMPTZ  │ 생성 시각                     │  │
│  └───────────────────┴──────────────┴─────────────────────────────┘  │
│         │ 0..1                                                         │
│       triggers                                                         │
│         │ 0..*                                                         │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ prompts                                                          │  │
│  ├───────────────────┬──────────────┬─────────────────────────────┤  │
│  │ id                │ INT          │ PK · 자동 증가                │  │
│  │ user_id           │ INT          │ FK → users.id                │  │
│  │ date              │ DATE         │ 프롬프트 날짜                  │  │
│  │ content           │ TEXT         │ 프롬프트 내용                  │  │
│  │ basis_schedule_id │ INT          │ FK → schedules.id (nullable) │  │
│  │ created_at        │ TIMESTAMPTZ  │ 생성 시각                     │  │
│  └───────────────────┴──────────────┴─────────────────────────────┘  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
