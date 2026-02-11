from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
import os
import json
from dotenv import load_dotenv
from src.prompts import get_prompt_for_diary_writing
from src.prompts import get_prompt_for_emotion_analysis
from src.emotion_service import analyze_emotions

load_dotenv()

app = FastAPI()

# CORS 설정 (Flutter Web에서 접근 가능하도록)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 구체적인 도메인 지정
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# 요청 모델
class ChatRequest(BaseModel):
    messages: list[dict[str, str]]

class ChatResponse(BaseModel):
    response: str
    emotion: str
    color: str

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Emotion Calendar API"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        # OpenAI API 호출
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[get_prompt_for_diary_writing(), *request.messages],
            max_tokens=200
        )
        
        response_text = completion.choices[0].message.content
        
        # 감정 추출
        emotion = {
            "분노": 0.0,
            "기대": 0.0,
            "기쁨": 0.0,
            "신뢰": 0.0,
            "공포": 0.0,
            "놀람": 0.0,
            "슬픔": 0.0,
            "혐오": 0.0,
            "중립": 0.0
        }
        if "[EMOTION:" in response_text:
            emotion_start = response_text.find("[EMOTION:") + 9
            emotion_end = response_text.find("]", emotion_start)
            emotion = response_text[emotion_start:emotion_end].strip()
            # [EMOTION:...] 부분 제거
            response_text = response_text.replace(f"[EMOTION:{emotion}]", "").strip()
        
        return ChatResponse(
            response=response_text,
            emotion=emotion,
            color=analyze_emotions(emotion)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 감정 분석만 하는 엔드포인트 (추가 기능)
@app.post("/analyze-emotion")
async def analyze_emotion(text: str):
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[ get_prompt_for_emotion_analysis(),
                {
                    "role": "user",
                    "content": text
                }
            ],
            max_tokens=10
        )
        
        emotion = completion.choices[0].message.content.strip().lower()
        emotion_json = json.loads(emotion)

        return {
            "emotion": emotion,
            "color": EMOTION_COLORS.get(emotion, EMOTION_COLORS["neutral"])
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))