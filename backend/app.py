from __future__ import annotations
import os
from dotenv import load_dotenv 
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel, Field
from src.emotion_service import emotion_to_color, extract_emotion_tag, parse_emotion_payload
from src.prompts import get_prompt_for_diary_writing, get_prompt_for_emotion_analysis, get_rag_context_prompt
from src.rag_service import MemoryRAGStore

load_dotenv()

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
rag_store = MemoryRAGStore()

class ChatMessage(BaseModel):
    role: str
    content: str

# 요청 모델
class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(default_factory=list)
class ChatResponse(BaseModel):
    response: str
    emotion: str
    color: str
    retrieval_context: list[str] = Field(default_factory=list)

class EmotionAnalysisResponse(BaseModel):
    text: str

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Emotion Calendar API"}

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
            max_tokens=250,
        )
        
        response_text = completion.choices[0].message.content or ""
        clean_text, emotion = extract_emotion_tag(response_text)

        rag_store.add_memory(f"USER: {last_user_message}")
        rag_store.add_memory(f"ASSISTANT: {clean_text}", metadata={"emotion": emotion})

        return ChatResponse(
            response=clean_text,
            emotion=emotion,
            color=emotion_to_color(emotion),
            retrieval_context=retrieved_contexts
        )
    
    except HTTPException:
        raise 
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

# 감정 분석만 하는 엔드포인트 (추가 기능)
@app.post("/analyze-emotion")
async def analyze_emotion(request: EmotionAnalysisResponse):
    try:
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