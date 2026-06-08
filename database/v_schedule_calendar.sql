-- 일정 캘린더 조회용 뷰 — KST 날짜/월 컬럼을 미리 계산해 쿼리를 단순화
--
-- 실행 위치: Supabase 대시보드 > SQL Editor

CREATE VIEW v_schedule_calendar AS
SELECT
    id,
    user_id,
    title,
    description,
    is_done,
    created_at,
    scheduled_at, 
    (scheduled_at AT TIME ZONE 'Asia/Seoul')::date     AS scheduled_date, 
    to_char(scheduled_at AT TIME ZONE 'Asia/Seoul', 'YYYY-MM') AS scheduled_month 
FROM schedules;
