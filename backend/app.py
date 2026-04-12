from __future__ import annotations
import os
import json
from contextlib import asynccontextmanager
from datetime import date as date_type
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel, Field
from src.emotion_service import emotion_to_color
from src.prompts import (
    get_prompt_for_daily_summary,
    get_prompt_for_diary_writing,
    get_prompt_for_emotion_analysis,
    get_rag_context_prompt
    )
from src.rag_service import MemoryRAGStore
from src import database
from src.repositories import diaries as diary_repo
from src.repositories import schedules as schedule_repo

load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    await database.create_pool()
    yield
    await database.close_pool()

app = FastAPI(lifespan=lifespan)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 응답 출력
@app.middleware("http")
async def log_responses(request: Request, call_next):
    response = await call_next(request)

    response_body = b""
    async for chunk in response.body_iterator:
        response_body += chunk

    try:
        print("\n----------------------------------------------------------------")
        print(f"\n[Response to {request.url.path}]")
        print(json.dumps(json.loads(response_body.decode()), indent=4, ensure_ascii=False))
    except:
        print(response_body.decode())

    return Response(
        content=response_body,
        status_code=response.status_code,
        headers=dict(response.headers),
        media_type=response.media_type
    )

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) #huggingface 환경변수
rag_store = MemoryRAGStore()

class ChatMessage(BaseModel):
    role: str
    content: str

# 요청 모델
class ChatRequest(BaseModel):
    user_id: int
    messages: list[ChatMessage] = Field(default_factory=list)

class AddSchedule(BaseModel):
    title: str
    description: str
    due_date: str

class ChatAction(BaseModel):
    save_diary: bool = False
    add_schedule: AddSchedule | None = None

class ChatResponse(BaseModel):
    type: str
    chat: str
    emotion: str
    color: str
    action: ChatAction | None = None
    retrieval_context: list[str] = Field(default_factory=list)

class DiaryEntry(BaseModel):
    user_id: int
    date: date_type
    messages: list[ChatMessage]
    summary: str | None = None
    emotion: str | None = None
    color: str | None = None

class DiaryResponse(BaseModel):
    id: int
    user_id: int
    date: date_type
    messages: list
    summary: str | None
    emotion: str | None
    color: str | None
    created_at: str

class EmotionAnalysisResponse(BaseModel):
    text: str

class DailySummaryResponse(BaseModel):
    summary: str

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Emotion Calendar API"}

# 채팅 엔드포인트
@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        if not request.messages:
            raise HTTPException(status_code=400, detail="messages is required")

        last_user_message = next(
            (m.content for m in reversed(request.messages) if m.role == "user"),
            request.messages[-1].content,
        )

        retrieved = rag_store.retrieve(last_user_message, k=3)
        retrieved_contexts = [item["text"] for item in retrieved]

        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[get_prompt_for_diary_writing(),
                      get_rag_context_prompt(retrieved_contexts),
                      *[msg.model_dump() for msg in request.messages]],
            max_tokens=500,
            response_format={"type": "json_object"},
        )

        response_text = (completion.choices[0].message.content or "").strip()
        # LLM이 마크다운 코드블록으로 감쌀 경우 제거
        if response_text.startswith("```"):
            response_text = response_text.split("\n", 1)[-1].rsplit("```", 1)[0].strip()

        parsed = json.loads(response_text)
        chat_text = parsed.get("chat", "")
        response_type = parsed.get("type", "diary")
        emotion_data = parsed.get("emotion_data") or {}
        emotion = emotion_data.get("label", "중립")
        action_data = parsed.get("action")
        action = None
        if action_data:
            add_schedule_data = action_data.get("add_schedule")
            action = ChatAction(
                save_diary=action_data.get("save_diary", False),
                add_schedule=AddSchedule(**add_schedule_data) if add_schedule_data else None,
            )

        if action and action.add_schedule:
            s = action.add_schedule
            await schedule_repo.create_schedule(
                user_id=request.user_id,
                title=s.title,
                scheduled_at=s.due_date,
                description=s.description,
            )

        rag_store.add_memory(f"USER: {last_user_message}")
        rag_store.add_memory(f"ASSISTANT: {chat_text}", metadata={"emotion": emotion})

        return ChatResponse(
            type=response_type,
            chat=chat_text,
            emotion=emotion,
            color=emotion_to_color(emotion),
            action=action,
            retrieval_context=retrieved_contexts,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

# 감정 분석 엔드포인트
# 사용 안함
@app.post("/analyze-emotion")
async def analyze_emotion(request: EmotionAnalysisResponse):
    try:
        from src.emotion_service import parse_emotion_payload
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                get_prompt_for_emotion_analysis(),
                {
                    "role": "user",
                    "content": request.text
                },
            ],
            max_tokens=100,
        )

        emotion_raw = (completion.choices[0].message.content or "").strip()
        emotion = parse_emotion_payload(emotion_raw)

        return {
            "emotion": emotion,
            "color": emotion_to_color(emotion),
            "raw": emotion_raw,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

# 일기 요약 엔드포인트
@app.post("/daily-summary", response_model=DailySummaryResponse)
async def daily_summary(request: ChatRequest):
    try:
        if not request.messages:
            raise HTTPException(status_code=400, detail="messages is required")

        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                get_prompt_for_daily_summary(),
                *[msg.model_dump() for msg in request.messages],
            ],
            max_tokens=180,
        )

        summary = (completion.choices[0].message.content or "").strip()
        return DailySummaryResponse(summary=summary)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

def _row_to_diary_response(row: dict) -> DiaryResponse:
    return DiaryResponse(
        id=row["id"],
        user_id=row["user_id"],
        date=row["date"],
        messages=row["messages"],
        summary=row["summary"],
        emotion=row["emotion"],
        color=row["color"],
        created_at=row["created_at"],
    )

# 사용자의 일기를 저장하는 엔드포인트
@app.post("/diary", response_model=DiaryResponse)
async def save_diary(entry: DiaryEntry):
    try:
        row = await diary_repo.save_diary(
            user_id=entry.user_id,
            date=entry.date,
            messages=[m.model_dump() for m in entry.messages],
            summary=entry.summary,
            emotion=entry.emotion,
            color=entry.color,
        )
        return _row_to_diary_response(row)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

# 사용자의 일기를 조회하는 엔드포인트
@app.get("/diary", response_model=DiaryResponse)
async def get_diary(user_id: int, date: str):
    try:
        row = await diary_repo.get_diary_by_user_and_date(user_id, date)
        if row is None:
            raise HTTPException(status_code=404, detail="해당 날짜의 일기를 찾을 수 없습니다.")
        return _row_to_diary_response(row)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e