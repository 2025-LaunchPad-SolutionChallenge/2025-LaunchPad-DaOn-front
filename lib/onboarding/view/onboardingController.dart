import 'package:flutter/material.dart';
import 'package:project_daon/common/view/new.dart';
import 'package:project_daon/onboarding/api/onboardingApi.dart';
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

  Future<void> _handleNext(dynamic answer) async {
    _userAnswers[_currentIndex] = answer;

    int disasterQuestionIndex = OnboardingData.section1Profile.length;

    // ⭐ 핵심 해결: type 검사를 완전히 빼버리고, 무조건 '재난 선택' 순서일 때만 분기 로직을 탑니다.
    // (이러면 뒤에서 type 4인 '피해 정도' 화면을 만나도 절대 이 로직을 타지 않습니다)
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
      // 마지막 페이지: register(신규 사용자만) → survey 제출 → 홈
      final onboardingApi = OnboardingApi();

      try {
        await onboardingApi.registerUser(_userAnswers);
      } catch (e) {
        debugPrint('[온보딩] register 실패: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입에 실패했습니다. 다시 시도해 주세요.\n${e.toString()}'),
          ),
        );
        return; // 등록 실패 시 홈으로 이동하지 않음
      }

      await onboardingApi.submitSurvey(_userAnswers, _selectedDisaster);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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

          if (currentSection == 1) {
            sectionCurrentPage = index + 1;
            sectionTotalPage = OnboardingData.section1Profile.length;
          } else if (currentSection == 2) {
            sectionCurrentPage =
                index - OnboardingData.section1Profile.length + 1;

            int detailLength = _selectedDisaster.isNotEmpty
                ? (OnboardingData
                          .section2DisasterDetails[_selectedDisaster]
                          ?.length ??
                      0)
                : (OnboardingData.section2DisasterDetails['홍수']?.length ?? 6);

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

            isMultipleSelection: stepData.isMultipleSelection,

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
