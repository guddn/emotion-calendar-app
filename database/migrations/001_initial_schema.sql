-- Migration 001: Initial schema
-- Creates users, diaries, schedules, prompts tables

CREATE TABLE IF NOT EXISTS users (
    id                 SERIAL PRIMARY KEY,
    auth_provider_id   TEXT        NOT NULL UNIQUE,
    email              TEXT,
    nickname           TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS diaries (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date        DATE        NOT NULL,
    messages    JSONB       NOT NULL,
    summary     TEXT,
    emotion     VARCHAR(20),
    color       VARCHAR(7),
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, date)
);

CREATE TABLE IF NOT EXISTS schedules (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title         TEXT        NOT NULL,
    description   TEXT,
    scheduled_at  TIMESTAMPTZ NOT NULL,
    is_done       BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS prompts (
    id                  SERIAL PRIMARY KEY,
    user_id             INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date                DATE        NOT NULL,
    content             TEXT        NOT NULL,
    basis_schedule_id   INTEGER     REFERENCES schedules(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
