import 'dailyStatusQuestion.dart';

class DailyStatusData {
  static final List<DailyStatusQuestion> questions = [
    DailyStatusQuestion(
      question: '오늘의 마음 상태는\n어떤가요?',
      options: ['매우 힘들어요', '그냥 버텼어요', '조금 나아졌어요', '비교적 괜찮았어요'],
      scoreField: 'emotionScore',
    ),
    DailyStatusQuestion(
      question: '몸 컨디션은\n어떤 편인가요?',
      options: ['많이 지쳤어요', '조금 피곤해요', '보통이에요', '괜찮아요'],
      scoreField: 'energyScore',
    ),
    DailyStatusQuestion(
      question: '오늘 하루, 어떤 행동을\n했나요?',
      options: [
        '아무 것도 못 했어요',
        '쉬는 시간을 가졌어요',
        '해야 할 일을 하나라도 했어요',
        '누군가와 대화를 했어요',
        '집 밖에 나갔어요',
      ],
      isMultipleSelection: true,
      scoreField: 'activityScore',
    ),
    DailyStatusQuestion(
      question: '오늘이 평소와 비교해\n어땠나요?',
      options: ['더 힘들어요', '비슷해요', '조금 나아졌어요'],
      scoreField: 'recoveryScore',
    ),
    DailyStatusQuestion(
      question: '지금 나에게 필요한 것은\n무엇인가요?',
      options: [
        '누군가의 도움이 필요해요',
        '잘 모르겠어요',
        '혼자만의 시간이 필요해요',
        '쉬고 싶어요',
        '정리하는 것이 필요해요',
      ],
      scoreField: 'needScore',
    ),
  ];
}
