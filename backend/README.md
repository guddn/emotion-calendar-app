---
title: Emotion Calendar App
emoji: 🏃
colorFrom: purple
colorTo: blue
sdk: docker
pinned: false
short_description: emotion_calendar_app backend api server
---

## Endpoints

### `POST /chat`
사용자 채팅 내역을 기반으로 RAG 검색 후 OpenAI API로 답변 생성

**Request**
```json
{
  "messages": [
    { "role": "user", "content": "오늘 기분이 좋아" }
  ]
}
```

**Response**
```json
{
  "response": "좋은 하루를 보내셨군요!",
  "emotion": "기쁨",
  "color": "#FFFF00",
  "retrieval_context": []
}
```

---

### `POST /analyze-emotion`
텍스트를 기반으로 감정 분석 및 색상 반환

**Request**
```json
{
  "text": "오늘 너무 힘들었어"
}
```

**Response**
```json
{
  "emotion": "슬픔",
  "color": "#0000FF",
  "raw": "슬픔"
}
```

---

### `POST /daily-summary`
대화 내역을 기반으로 하루 일기 요약 생성

**Request**
```json
{
  "messages": [
    { "role": "user", "content": "오늘 친구랑 싸웠어" },
    { "role": "assistant", "content": "많이 속상하셨겠어요." }
  ]
}
```

**Response**
```json
{
  "summary": "오늘 친구와 다툼이 있었고 속상한 하루를 보냈다."
}
```

---

### `POST /diary`
사용자 일기를 DB에 저장 (같은 날짜가 있으면 덮어씀)

**Request**
```json
{
  "user_id": 1,
  "date": "2026-04-03",
  "messages": [],
  "summary": "오늘은 좋은 하루였다.",
  "emotion": "기쁨",
  "color": "#FFFF00"
}
```

**Response**
```json
{
  "id": 1,
  "user_id": 1,
  "date": "2026-04-03",
  "messages": [],
  "summary": "오늘은 좋은 하루였다.",
  "emotion": "기쁨",
  "color": "#FFFF00",
  "created_at": "2026-04-03T12:00:00+00:00"
}
```

---

### `GET /diary`
사용자의 특정 날짜 일기 조회

**Query Parameters**
- `user_id` (int)
- `date` (string, YYYY-MM-DD)

**Response** — `POST /diary`와 동일한 형식, 없으면 `404`

---

Check out the configuration reference at https://huggingface.co/docs/hub/spaces-config-reference
