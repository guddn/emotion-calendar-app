# 사용자의 답변을 기반으로 감정 분석 및 색상 추출

def analyze_emotions(response_text):
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