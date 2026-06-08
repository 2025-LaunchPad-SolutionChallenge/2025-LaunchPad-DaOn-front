class OnboardingQuestion {
  final int section;
  final int type; // view 구분
  final String question; // section 공통 : 질문
  final List<String>? options; // section 1 : 선택지

  final String? seconText; // section 2,3 : 검색창 힌트
  final String? hintText; // section 2,3 : 검색창 힌트
  final String? btnText; // section 2 : 버튼 속 텍스트
  final int? num; // 최대 글자 수 (type 2: 이름/닉네임, type 3: 주소)
  final bool? isMultipleSelection;
  // type 2 텍스트 필드의 입력 형식 구분: 'name' | 'birthDate' | 'nickname'
  final String? inputFormat;

  OnboardingQuestion({
    required this.section,
    required this.type,
    required this.question,
    this.options,
    this.seconText,
    this.hintText,
    this.btnText,
    this.num,
    this.isMultipleSelection = false,
    this.inputFormat,
  });

  // factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
  //   return OnboardingQuestion(title: json['title'] ?? '');
  // }
  //
  // Map<String, dynamic> toJson() {
  //   return {'title': title};
  // }
}
