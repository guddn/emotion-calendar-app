-- schedules에 새 행이 INSERT될 때마다 prompts에 자동으로 행을 생성하는 Trigger
--
-- 실행 위치: Supabase 대시보드 > SQL Editor
-- 실행 순서: 1. 함수 생성 → 2. 트리거 생성

-- ──────────────────────────────────────────────
-- 1. 트리거 함수
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_schedule_to_prompt()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO prompts (user_id, date, content, basis_schedule_id)
    VALUES (
        NEW.user_id,
        -- scheduled_at(UTC)을 KST 기준 날짜로 변환
        (NEW.scheduled_at AT TIME ZONE 'Asia/Seoul')::date,
        -- content: "제목 (설명)" 또는 "제목"
        NEW.title || CASE
            WHEN NEW.description IS NOT NULL AND trim(NEW.description) <> ''
            THEN ' (' || trim(NEW.description) || ')'
            ELSE ''
        END,
        NEW.id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ──────────────────────────────────────────────
-- 2. 트리거 등록
-- ──────────────────────────────────────────────
CREATE TRIGGER trg_auto_create_prompt
AFTER INSERT ON schedules
FOR EACH ROW
EXECUTE FUNCTION fn_schedule_to_prompt();
