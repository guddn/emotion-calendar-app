# Backend 구상안 (Python + Hugging Face CPU)

## 1) 목표
- 캐릭터형 대화 UI를 지원하는 API 제공
- 대화 응답에서 감정을 추출해 캘린더 색상으로 연결
- RAG(top-3) 기반으로 과거 대화를 맥락에 반영
- 일정 요청 문장을 구조화해서 일정 탭 자동 업데이트 가능하도록 확장

## 2) 현재 코드 기준 반영 사항
- `app.py`
  - `/chat`에서 최근 유저 문장으로 RAG top-3 검색
  - 검색 결과를 system context로 주입 후 응답 생성
  - 응답 내 `[EMOTION:...]` 태그를 파싱해 `emotion`, `color` 반환
- `src/emotion_service.py`
  - 감정 태그 파싱 + 한/영 감정명 정규화 + 색상 매핑
  - JSON 감정 벡터도 받아 dominant emotion 계산
- `src/rag_service.py`
  - Hugging Face `sentence-transformers` 모델을 CPU로 로드
  - 대화 메모리 인메모리 저장/조회 (`retrieve(k=3)`)

## 3) 권장 확장 단계
1. **메모리 영속화**
   - SQLite 또는 Postgres + pgvector 도입
   - `user_id`, `date`, `conversation_turn` 기준 저장
2. **일정 추출 파이프라인**
   - 별도 endpoint: `/calendar/extract`
   - 출력 스키마: `{title, date, time, place, status}`
3. **감정탭 상세 조회**
   - endpoint: `/calendar/emotion/{date}`
   - 날짜별 대화 + 감정 intensity + weather metadata
4. **일정 완료 자동 반영**
   - "끝냈어/완료했어" intent 분류 후 status=done
5. **운영 안정화**
   - rate limiting, structured logging, tracing(OpenTelemetry)

## 4) API 초안
- `POST /chat`
  - input: `messages[]`
  - output: `response`, `emotion`, `color`, `retrieved_contexts[]`
- `POST /analyze-emotion`
  - input: `text`
  - output: `emotion`, `color`, `raw`

## 5) 모델/인프라 제안
- 대화 생성: OpenAI (`gpt-4o-mini`)
- 임베딩(RAG): Hugging Face sentence-transformers (CPU)
- 감정 후처리: rule-based parser + color mapper
- 배포: FastAPI + Uvicorn (Docker), 추후 Redis 캐시 추가

## 6) 제품 관점 메모
- 타겟(10~20대)에 맞춰 **짧고 공감형 문체** 유지
- 캘린더 입력 부담을 줄이기 위해 **자연어 일정 추출 정확도**를 핵심 KPI로 설정
- 귀여운 캐릭터 톤 일관성을 위해 prompt style guide 파일 분리 권장
