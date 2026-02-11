from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
import os
from dotenv import load_dotenv

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

# 감정-색상 매핑
EMOTION_COLORS = {
    "분노": "#FF4500",
    "기대": "#FFA500",
    "기쁨": "#FFFF00",
    "신뢰": "#7FFF00",
    "공포": "#00FF00",
    "놀람": "#00FFFF",
    "슬픔": "#0000FF",
    "혐오": "#800080",
    "중립": "#FFFFFF"
}

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Emotion Calendar API"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        # OpenAI API 호출
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": """
역할
- 당신은 사용자의 일정을 관리하고 감정 일기를 함께 작성하는 친근한 캐릭터입니다.
- 가장 먼저 사용자의 입력이 일정을 관리 목적인지, 감정 일기 목적인지 판단합니다.

일정 관리
- 사용자가 일정 관리를 요청하면, 일정의 날짜, 시간, 장소, 내용 등을 명확히 묻고 기록합니다.

감정 일기
- 사용자가 감정 일기를 작성하면, 그날의 기분, 이유, 특별한 사건 등을 상세히 묻고 기록합니다.

주의사항
- 응답은 한국어로 작성합니다.
- 응답 끝에 [EMOTION:...] 형식으로 사용자의 감정을 나타냅니다. (happy/sad/angry/tired/neutral 중 하나)
- 사용자의 감정을 직접적으로 판단하지 않습니다. 사용자의 표현을 바탕으로 감정을 유추합니다.
"""
                },
                *request.messages
            ],
            max_tokens=200
        )
        
        response_text = completion.choices[0].message.content
        
        # 감정 추출
        emotion = "neutral"
        if "[EMOTION:" in response_text:
            emotion_start = response_text.find("[EMOTION:") + 9
            emotion_end = response_text.find("]", emotion_start)
            emotion = response_text[emotion_start:emotion_end].strip()
            # [EMOTION:...] 부분 제거
            response_text = response_text.replace(f"[EMOTION:{emotion}]", "").strip()
        
        return ChatResponse(
            response=response_text,
            emotion=emotion,
            color=EMOTION_COLORS.get(emotion, EMOTION_COLORS["neutral"])
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 감정 분석만 하는 엔드포인트 (추가 기능)
@app.post("/analyze-emotion")
async def analyze_emotion(text: str):
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": '''
당신은 심리 분석 전문가입니다. 
사용자의 일기를 읽고 로버트 플루치크(Robert Plutchik)의 8가지 기본 감정(기쁨, 신뢰, 공포, 놀람, 슬픔, 혐오, 분노, 기대)을 기준으로 각 감정이 차지하는 비율을 0.0에서 1.0 사이의 소수로 분석하여 JSON으로 반환하세요. 
모든 비율의 합이 1.0이 될 필요는 없습니다. 
비율은 각 감정의 강도를 나타냅니다.
'''
                },
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