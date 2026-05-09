class OnboardingQuestion {
  final int section;
  final int type; // page 구분
  final String question; // section 공통 : 질문
  final List<String>? options; // section 1 : 선택지

  final String? seconText; // section 2,3 : 검색창 힌트
  final String? hintText; // section 2,3 : 검색창 힌트
  final String? btnText; // section 2 : 버튼 속 텍스트
  final int? num; // section 3 : 글자수
  final bool? isMultipleSelection;

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
  });

  // factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
  //   return OnboardingQuestion(title: json['title'] ?? '');
  // }
  //
  // Map<String, dynamic> toJson() {
  //   return {'title': title};
  // }
}
