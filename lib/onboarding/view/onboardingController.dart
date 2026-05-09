import 'package:flutter/material.dart';
import '../model/onboardingQuestion.dart';
import 'onboardingType.dart';
import '../model/onboardingData.dart';

class OnboardingController extends StatefulWidget {
  const OnboardingController({Key? key}) : super(key: key);

  @override
  State<OnboardingController> createState() => _OnboardingControllerState();
}

class _OnboardingControllerState extends State<OnboardingController> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, dynamic> _userAnswers = {};

  List<OnboardingQuestion> _currentSteps = [];
  String _selectedDisaster = '';

  @override
  void initState() {
    super.initState();
    // 초기 세팅: 섹션 1(프로필) + 섹션 2의 첫 질문(재난 종류 선택)
    _currentSteps.addAll(OnboardingData.section1Profile);
    _currentSteps.addAll(OnboardingData.section2DisasterBase);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext(dynamic answer) {
    _userAnswers[_currentIndex] = answer;

    int disasterQuestionIndex = OnboardingData.section1Profile.length;

    // 분기점: '어떤 재난을 겪으셨나요?' (섹션 2의 첫 페이지) 일 때
    if (_currentIndex == disasterQuestionIndex) {
      String newDisaster = (answer as List<String>).first;

      if (_selectedDisaster != newDisaster) {
        _selectedDisaster = newDisaster;

        setState(() {
          // 기존에 붙어있던 상세 질문들 자르기
          if (_currentSteps.length > disasterQuestionIndex + 1) {
            _currentSteps.removeRange(
              disasterQuestionIndex + 1,
              _currentSteps.length,
            );
          }

          // 선택한 재난에 맞는 상세 질문 이어 붙이기
          if (OnboardingData.section2DisasterDetails.containsKey(
            _selectedDisaster,
          )) {
            _currentSteps.addAll(
              OnboardingData.section2DisasterDetails[_selectedDisaster]!,
            );
          }
        });
      }
    }

    // 다음 페이지로 이동
    if (_currentIndex < _currentSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      print('최종 수집된 데이터: $_userAnswers');
      // Navigator.push(...) 로 메인으로 이동
    }
  }

  void _handlePrevious() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _currentSteps.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final stepData = _currentSteps[index];
          final currentSection = stepData.section;

          int sectionCurrentPage = 1;
          int sectionTotalPage = 1;

          // ⭐ 핵심 해결: 버그가 나던 indexOf를 빼고, 절대적인 index(순서)로 계산합니다.
          if (currentSection == 1) {
            // [섹션 1] 프로필 (진행률: 1/4 ~ 4/4)
            sectionCurrentPage = _currentIndex + 1;
            sectionTotalPage = OnboardingData.section1Profile.length;
          } else if (currentSection == 2) {
            // [섹션 2] 재난 관련 질문 전체를 하나의 섹션으로 묶음
            // 현재 페이지 번호: 내 인덱스 - (섹션 1의 길이) + 1
            sectionCurrentPage =
                _currentIndex - OnboardingData.section1Profile.length + 1;

            // 섹션 2의 총 질문 개수 = 1(재난선택) + 선택한 재난의 세부 질문 개수
            int detailLength = _selectedDisaster.isNotEmpty
                ? (OnboardingData
                          .section2DisasterDetails[_selectedDisaster]
                          ?.length ??
                      0)
                // 아직 재난을 선택하기 전(1페이지)이라면, 기본적으로 가장 긴 홍수(6개)를 기준으로 잡아줍니다.
                : (OnboardingData.section2DisasterDetails['홍수/침수']?.length ??
                      6);

            sectionTotalPage = 1 + detailLength;
          }

          return OnboardingType(
            onboardingType: stepData.type,
            question: stepData.question,
            options: stepData.options,
            seconText: stepData.seconText,
            hintText: stepData.hintText,
            btnText: stepData.btnText,
            num: stepData.num,

            // 계산된 완벽한 진행률 전달
            currentPage: sectionCurrentPage,
            totalPage: sectionTotalPage,

            onPrevious: _handlePrevious,
            onNext: (answer) => _handleNext(answer),
          );
        },
      ),
    );
  }
}
