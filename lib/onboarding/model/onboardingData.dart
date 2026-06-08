import 'onboardingQuestion.dart';

class OnboardingData {
  // ==========================================
  // [섹션 1] 가입 기본 정보
  // ==========================================
  static final List<OnboardingQuestion> section1Profile = [
    OnboardingQuestion(
      section: 1,
      type: 2,
      seconText: '기본 정보 입력',
      question: '본인의 이름을\n입력해주세요.',
      hintText: '이름을 입력해주세요.',
      num: 6,           // 최대 6자
      inputFormat: 'name',
    ),
    OnboardingQuestion(
      section: 1,
      type: 2,
      seconText: '기본 정보 입력',
      question: '생년월일을\n입력해주세요.',
      hintText: '예) 2004.03.12',
      inputFormat: 'birthDate', // YYYY.MM.DD 자동 포맷
    ),
    OnboardingQuestion(
      section: 1,
      type: 2,
      seconText: '기본 정보 입력',
      question: '사용할 닉네임을\n입력해주세요.',
      hintText: '닉네임을 설정해주세요.',
      num: 10,          // 최대 10자
      inputFormat: 'nickname',
    ),
    OnboardingQuestion(
      section: 1,
      type: 3,
      seconText: '기본 정보 입력',
      question: '피해를 받은 장소의\n주소를 입력해주세요.',
      hintText: '예) 연희동 132, 도산대로 33',
      btnText: '검색',
    ),
  ];

  // ==========================================
  // [섹션 2] 재난 정보 (종류 선택 + 상세 질문)
  // ==========================================

  // 1) 섹션 2의 첫 번째 질문: 재난 종류 선택
  static final List<OnboardingQuestion> section2DisasterBase = [
    OnboardingQuestion(
      section: 2,
      type: 4,
      seconText: '나의 재난 정보 입력',
      question: '어떤 재난을\n겪으셨나요?',
      options: ['홍수', '태풍', '지진', '화재'],
    ),
  ];

  // 2) 선택에 따라 달라지는 섹션 2의 상세 질문들
  static final Map<String, List<OnboardingQuestion>> section2DisasterDetails = {
    '홍수': [
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '지금 상황에 가장 가까운 상태를\n선택해주세요.',
        options: ['안전한 상태에요', '약간의 피해가 있어요', '피해가 발생했어요', '긴급한 도움이 필요해요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 집에서 정상적으로\n거주가 가능하신가요?',
        options: ['정상적으로 거주 가능해요', '일부 파손되었지만 거주 가능해요', '현재 거주하기 어려워요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '다치신 곳이나\n몸 상태는 괜찮으신가요?',
        options: ['괜찮아요', '가벼운 부상이 있어요(경상)', '치료가 필요해요(중상)'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 4,
        isMultipleSelection: true,
        seconText: '나의 재난 정보 입력',
        question: '현재 어떤 피해를\n겪고 계신가요? (복수 선택)',
        options: ['주거 공간 피해', '차량 피해', '전기 문제', '수도 문제', '심리적 불안감'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 머무시는 곳의 침수 정도는\n어느 정도인가요?',
        options: ['침수되지 않았어요', '집 앞이 침수되었어요', '1층이 침수되었어요', '집 내부까지 침수되었어요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '침수되었던 물은\n어느 정도 빠진 상태인가요?',
        options: ['아직 물이 고여있어요', '일부 빠졌어요', '대부분 빠졌어요'],
      ),
    ],

    '태풍': [
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '지금 상황에 가장 가까운 상태를\n선택해주세요.',
        options: ['안전한 상태에요', '약간의 피해가 있어요', '피해가 발생했어요', '긴급한 도움이 필요해요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 집에서 정상적으로\n거주가 가능하신가요?',
        options: ['정상적으로 거주 가능해요', '일부 파손되었지만 거주 가능해요', '현재 거주하기 어려워요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '다치신 곳이나\n몸 상태는 괜찮으신가요?',
        options: ['괜찮아요', '가벼운 부상이 있어요(경상)', '치료가 필요해요(중상)'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 4,
        isMultipleSelection: true,
        seconText: '나의 재난 정보 입력',
        question: '현재 어떤 피해를\n겪고 계신가요? (복수 선택)',
        options: [
          '지붕 파손',
          '창문 파손',
          '간판 및 구조물 피해',
          '차량 피해',
          '전기 문제',
          '수도 문제',
          '부상',
          '심리적 불안감',
        ],
      ),
    ],

    '지진': [
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '지금 상황에 가장 가까운 상태를\n선택해주세요.',
        options: ['안전한 상태에요', '약간의 피해가 있어요', '피해가 발생했어요', '긴급한 도움이 필요해요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 집에서 정상적으로\n거주가 가능하신가요?',
        options: ['정상적으로 거주 가능해요', '일부 파손되었지만 거주 가능해요', '현재 거주하기 어려워요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '다치신 곳이나\n몸 상태는 괜찮으신가요?',
        options: ['괜찮아요', '가벼운 부상이 있어요(경상)', '치료가 필요해요(중상)'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 4,
        isMultipleSelection: true,
        seconText: '나의 재난 정보 입력',
        question: '현재 어떤 피해를\n겪고 계신가요? (복수 선택)',
        options: [
          '건물 균열 발생',
          '주거 공간 피해',
          '차량 피해',
          '전기 문제',
          '수도 단수',
          '부상',
          '심리적 불안감',
        ],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 여진이 느껴지거나\n불안감이 있으신가요?',
        options: ['느껴지지 않아요', '가끔 느껴져요', '지속적으로 느껴져요'],
      ),
    ],

    '화재': [
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '지금 상황에 가장 가까운 상태를\n선택해주세요.',
        options: ['안전한 상태에요', '약간의 피해가 있어요', '피해가 발생했어요', '긴급한 도움이 필요해요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '현재 집에서 정상적으로\n거주가 가능하신가요?',
        options: ['정상적으로 거주 가능해요', '일부 파손되었지만 거주 가능해요', '현재 거주하기 어려워요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '다치신 곳이나\n몸 상태는 괜찮으신가요?',
        options: ['괜찮아요', '가벼운 부상이 있어요(경상)', '치료가 필요해요(중상)'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 4,
        isMultipleSelection: true,
        seconText: '나의 재난 정보 입력',
        question: '현재 어떤 피해를\n겪고 계신가요? (복수 선택)',
        options: [
          '주거 공간 피해',
          '차량 피해',
          '전기 문제',
          '수도 문제',
          '부상',
          '심리적 불안감',
          '그을음 피해',
          '화재 잔해 발생',
        ],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '화재로 인한 피해 범위는\n어느 정도인가요?',
        options: ['연기로 인한 피해만 있어요', '일부 공간이 소실되었어요', '집 전체에 피해를 입었어요'],
      ),
      OnboardingQuestion(
        section: 2,
        type: 1,
        seconText: '나의 재난 정보 입력',
        question: '화재 당시 연기를\n얼마나 들이마셨나요?',
        options: ['마시지 않았어요', '약간 마셨어요', '심하게 마셨어요'],
      ),
    ],
  };

  // ==========================================
  // [섹션 3] 오늘의 상태 체크 (두 번째 사진 화면들)
  // ==========================================
  static final List<OnboardingQuestion> section3DailyCheck = [
    OnboardingQuestion(
      section: 3,
      type: 1,
      question: '오늘의 마음 상태는\n어떤가요?',
      options: ['매우 힘들어요', '그냥 버텼어요', '조금 나아졌어요', '비교적 괜찮았어요'],
    ),
    OnboardingQuestion(
      section: 3,
      type: 1,
      question: '몸 컨디션은\n어떤 편인가요?',
      options: ['많이 지쳤어요', '조금 피곤해요', '보통이에요', '괜찮아요'],
    ),
    OnboardingQuestion(
      section: 3,
      type: 1,
      isMultipleSelection: true,
      question: '오늘 하루, 어떤 행동을\n했나요? (복수 선택)',
      options: [
        '아무 것도 못 했어요',
        '쉬는 시간을 가졌어요',
        '해야 할 일을 하나라도 했어요',
        '누군가와 대화를 했어요',
        '집 밖에 나갔어요',
      ],
    ),
    OnboardingQuestion(
      section: 3,
      type: 1,
      question: '오늘이 평소와 비교해\n어땠나요?',
      options: ['더 힘들어요', '비슷해요', '조금 나아졌어요'],
    ),
    OnboardingQuestion(
      section: 3,
      type: 1,
      question: '지금 나에게 필요한 것은\n무엇인가요?',
      options: [
        '누군가의 도움이 필요해요',
        '잘 모르겠어요',
        '혼자만의 시간이 필요해요',
        '쉬고 싶어요',
        '정리하는 것이 필요해요',
      ],
    ),
  ];
}
