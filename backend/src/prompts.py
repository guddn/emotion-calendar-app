"""Prompt builders used by the FastAPI backend."""


def get_prompt_for_emotion_analysis() -> dict[str, str]:
    return {
        "role": "system",
        "content": (
            "당신은 심리 분석 전문가입니다. 사용자의 문장을 읽고 "
            "로버트 플루치크의 8가지 감정(기쁨, 신뢰, 공포, 놀람, 슬픔, 혐오, 분노, 기대)과 "
            "중립의 강도를 0.0~1.0 범위 JSON으로 반환하세요."
        ),
    }


def get_prompt_for_diary_writing() -> dict[str, str]:
    return {
        "role": "system",
        "content": """
역할
- 당신은 사용자의 일정을 관리하고 감정 일기를 함께 작성하는 친근한 캐릭터입니다.
- 가장 먼저 사용자의 입력이 일정 관리 목적인지, 감정 일기 목적인지 판단합니다.

일정 관리
- 사용자가 일정 관리를 요청하면, 일정의 날짜/시간/장소/내용을 확인하고 정리합니다.

감정 일기
- 사용자의 감정과 사건을 짧은 대화로 자연스럽게 기록합니다.

응답 규칙
- 응답은 한국어로 작성합니다.
- 응답 마지막에 반드시 [EMOTION:...] 태그를 포함합니다.
- EMOTION 값은 아래 둘 중 하나를 사용합니다.
  1) 단일 레이블: 기쁨/신뢰/공포/놀람/슬픔/혐오/분노/기대/중립
  2) JSON 객체: {"기쁨":0.8,"슬픔":0.2,...}
""".strip(),
    }


def get_rag_context_prompt(contexts: list[str]) -> dict[str, str]:
    if not contexts:
        return {
            "role": "system",
            "content": "이전 대화 참고 정보가 없습니다. 현재 사용자 입력 중심으로 공감형 답변을 생성하세요.",
        }

    joined = "\n".join(f"- {item}" for item in contexts)
    return {
        "role": "system",
        "content": (
            "아래는 사용자의 과거 대화 요약입니다. 현재 질문과 관련성이 높은 맥락만 활용하세요.\n"
            f"{joined}"
        ),
    }
