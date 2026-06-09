import 'package:flutter/material.dart';
import 'package:project_daon/common/view/new.dart';
import 'package:project_daon/onboarding/api/onboardingApi.dart';
import '../model/onboardingData.dart';
import '../model/onboardingLocation.dart';
import '../model/onboardingQuestion.dart';
import 'onboardingType.dart';

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

    final int section1LastIndex = OnboardingData.section1Profile.length - 1;
    final int disasterQuestionIndex = OnboardingData.section1Profile.length;

    // Step 1 완료 시점(location 입력 후): register 호출 → 성공 시 거주지 인증 호출
    // register 성공 이후 accessToken이 존재하므로 verifyResidence에 app Dio를 사용합니다.
    if (_currentIndex == section1LastIndex) {
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
        return;
      }

      // register 성공 → accessToken 존재 → 거주지 인증 호출
      // verify API 호출 시점: register 직후 (section1LastIndex 처리 내부)
      final locationAnswer = _userAnswers[section1LastIndex];
      if (locationAnswer is! LocationConfirmResult) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 정보가 올바르지 않습니다. 다시 시도해 주세요.')),
        );
        return;
      }

      final loc = locationAnswer.location;
      if (loc.latitude == null || loc.longitude == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피해 장소 좌표를 확인할 수 없습니다. 위치를 다시 선택해 주세요.')),
        );
        return;
      }

      try {
        final verifyResult = await onboardingApi.verifyResidence(
          disasterLatitude: loc.latitude!,
          disasterLongitude: loc.longitude!,
          currentLatitude: locationAnswer.currentLatitude,
          currentLongitude: locationAnswer.currentLongitude,
          currentAddress: locationAnswer.currentAddress,
        );

        if (!verifyResult.verified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verifyResult.message)),
          );
          return;
        }

        debugPrint('[거주지 인증] 인증 성공 | distanceKm=${verifyResult.distanceKm}');
      } catch (e) {
        debugPrint('[온보딩] 거주지 인증 실패: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
        return;
      }
    }

    // 재난 종류 선택 시: 상세 질문 동적 로드
    if (_currentIndex == disasterQuestionIndex) {
      String newDisaster = (answer as List<String>).first;

      if (_selectedDisaster != newDisaster) {
        _selectedDisaster = newDisaster;

        setState(() {
          if (_currentSteps.length > disasterQuestionIndex + 1) {
            _currentSteps.removeRange(
              disasterQuestionIndex + 1,
              _currentSteps.length,
            );
          }
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
      // 마지막 페이지: 재난 피해 현황 제출 후 홈으로
      // register는 Step 1 완료 시 이미 처리되므로 accessToken이 존재함
      final onboardingApi = OnboardingApi();
      try {
        await onboardingApi.submitDisasterOnboarding(
          _userAnswers,
          _selectedDisaster,
        );
      } catch (e) {
        debugPrint('[온보딩] 재난 정보 제출 실패: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('재난 정보 등록에 실패했습니다. 다시 시도해 주세요.\n${e.toString()}'),
          ),
        );
        return; // 실패 시 홈 이동 없음
      }
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
            inputFormat: stepData.inputFormat,
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
