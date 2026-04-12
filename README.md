# emotion-calendar-app

## 캘린더 및 일기장 웹

기본 ui (캐릭터와 대화하는 형식)
* 처음 앱에 접속하면 캐릭터가 사용자의 일정을 기반으로 질문을 한다 (ex.오늘 과제는 어땠어?)
   * 거기에 간단하게 한두문장으로 답장을 하면 문장을 기반으로 감정을 분석하여 캘린더에 색으로 표시
      * 사용자의 감정에 따라 표정 및 행동이 변화하면 좋을듯
   * "일정을 (이렇게 저렇게) 기록해줘" 라고 사용자가 요청을 하면 캘린더에 일정을 기록해줌

RAG를 이용하여 사용자가 이전에 했던 말들 중에 retrieval top3를 골라서 프롬프트에 포함하여 답변하도록 설계.
* 예를 들어 "나 오늘 조별 과제야"라고 질문하면 이전 대화에서 유사도를 찾는다. "나 오늘 조별 과제하느라 너무 힘들었어" 라고 답변한 기록을 선별했다면 그걸 포함하여 "이번에도 조별과제구나 ㅜㅜ 힘들 수 있어도 화이팅해보자!" 와 같은 답변이 나오도록 유도

캘린더는 감정탭과 일정탭으로 구분됨
* 감정탭: 위에 말한 것처럼 사용자의 답변을 분석하여 색으로 표시하고, 날짜를 클릭하면 새로운 창에서 그 날 나눴던 감정의 대화들을 표시해줌 (날씨 등은 자동 기록)
* 일정탭: 일정을 기록해달라는 요청에 대하여 요청을 분석해서 자동으로 기록을 해주고, 사용자가 일정을 마쳤다고 답변하면 지워줌. 날짜를 클릭하면 AI가 분석한 그 날의 일정들을 알 수 있음. 마감기한같은 일정이 있으면 알림기능 추가하면 좋을듯

타겟 고객들
* LLM 서비스와 대화하는 것이 익숙한 10대~20대
* 캘린더에 일정을 하나하나 기록하는 것이 귀찮은 고객
* 일기를 쓰고 싶지만 시간이 없는 고객
* 자신의 감정을 정리하고 싶은 고객

openai api 이용처
* 기본적으로 대화형 (ex. 이번주는 조금 지쳐보이네요. 쉬는 시간을 갖는건 어떨까요?)를 ui에서 제공한다.
* 텍스트 기반 감정 분석, 시각적 색 선별, 일정 분석 및 정리

추가 고려사항
* 귀여운 디자인으로 하면 인기가 오를만한 컨텐츠인듯하다

---
## 업데이트
2026/04/03
- 기능추가
   - database/schema.sql — 전체 스키마 (users, diaries schedules, prompts)
   - database/migrations/001_initial_schema.sql — 초기 마이그레이션
   - backend/src/repositories/init.py
   - backend/src/repositories/users.py
   - backend/src/repositories/diaries.py
   - backend/src/repositories/schedules.py
   - backend/src/repositories/prompts.py

- 수정
   - backend/src/database.py — save_diary, get_diary_by_user_and_date, _create_tables, _serialize_row 제거 → pool 관리만 남김
   - backend/app.py — from src import database → from src.repositories import diaries as diary_repo 추가, database.save_diary / database.get_diary_by_user_and_date → diary_repo.* 로 변경

2026/04/12
- 기능 추가
   - 일정 관리 인터페이스 추가
   - 사용자의 채팅을 분석해서 scheduling이 가능하게 수정
   - schedule이 필요할 경우 일정 관리 인터페이스에 표시되도록 기능 추가

- 수정
   - date 변수와 datetime의 date 객체의 충돌 문제 해결
   - 백엔드 API 응답 json 형식으로 수정