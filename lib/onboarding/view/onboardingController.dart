import 'package:flutter/material.dart';
import 'package:project_daon/core/service/selected_disaster_service.dart';
import 'package:project_daon/onboarding/api/onboardingApi.dart';
import '../model/onboardingData.dart';
import '../model/onboardingLocation.dart';
import '../model/onboardingQuestion.dart';
import 'onboardingType.dart';

class OnboardingController extends StatefulWidget {
  // addDisasterMode=true 이면 section1(이름/생년월일/닉네임/주소) 없이
  // 재난 유형 선택부터 시작하고, 완료 시 새 userDisasterId를 pop합니다.
  final bool addDisasterMode;

  const OnboardingController({Key? key, this.addDisasterMode = false})
      : super(key: key);

  @override
  State<OnboardingController> createState() => _OnboardingControllerState();
}

class _OnboardingControllerState extends State<OnboardingController> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, dynamic> _userAnswers = {};

  List<OnboardingQuestion> _currentSteps = [];
  String _selectedDisaster = '';

  // 일반 온보딩: section1(4) + 재난유형(1) → 상세 시작 인덱스 = 5
  // 재난 추가 모드: 재난유형(1) → 상세 시작 인덱스 = 1
  int get _detailOffset => widget.addDisasterMode ? 1 : 5;

  // 재난 유형 질문의 _currentIndex
  int get _disasterTypeIndex =>
      widget.addDisasterMode ? 0 : OnboardingData.section1Profile.length;

  // section1 마지막 인덱스 (add-disaster 모드에서는 -1 → 절대 일치 안 함)
  int get _section1LastIndex =>
      widget.addDisasterMode ? -1 : OnboardingData.section1Profile.length - 1;

  @override
  void initState() {
    super.initState();
    if (widget.addDisasterMode) {
      // 재난 추가 모드: section1 생략, 재난 유형 선택부터 시작
      _currentSteps.addAll(OnboardingData.section2DisasterBase);
    } else {
      _currentSteps.addAll(OnboardingData.section1Profile);
      _currentSteps.addAll(OnboardingData.section2DisasterBase);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleNext(dynamic answer) async {
    _userAnswers[_currentIndex] = answer;

    // ── Step 1 완료: 회원가입 + 거주지 인증 (일반 온보딩 전용) ──
    if (_currentIndex == _section1LastIndex) {
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

      final locationAnswer = _userAnswers[_section1LastIndex];
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

    // ── 재난 종류 선택 시: 상세 질문 동적 로드 ──
    if (_currentIndex == _disasterTypeIndex) {
      final newDisaster = (answer as List<String>).first;

      if (_selectedDisaster != newDisaster) {
        _selectedDisaster = newDisaster;

        setState(() {
          if (_currentSteps.length > _disasterTypeIndex + 1) {
            _currentSteps.removeRange(
              _disasterTypeIndex + 1,
              _currentSteps.length,
            );
          }
          if (OnboardingData.section2DisasterDetails.containsKey(_selectedDisaster)) {
            _currentSteps.addAll(
              OnboardingData.section2DisasterDetails[_selectedDisaster]!,
            );
          }
        });
      }
    }

    // ── 다음 페이지 이동 or 최종 제출 ──
    if (_currentIndex < _currentSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final onboardingApi = OnboardingApi();

      try {
        final newUserDisasterId = await onboardingApi.submitDisasterOnboarding(
          _userAnswers,
          _selectedDisaster,
          detailOffset: _detailOffset,
        );

        if (!mounted) return;

        if (widget.addDisasterMode) {
          // 재난 추가 모드: 새 userDisasterId를 전역 서비스에 저장 후 pop
          if (newUserDisasterId != null) {
            await SelectedDisasterService.instance.select(newUserDisasterId);
          }
          if (!mounted) return;
          Navigator.of(context).pop(newUserDisasterId);
        } else {
          // 일반 온보딩: 홈 화면으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        }
      } catch (e) {
        debugPrint('[온보딩] 재난 정보 제출 실패: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('재난 정보 등록에 실패했습니다. 다시 시도해 주세요.\n${e.toString()}'),
          ),
        );
      }
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

          if (!widget.addDisasterMode && currentSection == 1) {
            sectionCurrentPage = index + 1;
            sectionTotalPage = OnboardingData.section1Profile.length;
          } else if (currentSection == 2) {
            // 재난 추가 모드: section1 오프셋 0, 일반: section1 오프셋 4
            final s1Len = widget.addDisasterMode ? 0 : OnboardingData.section1Profile.length;
            sectionCurrentPage = index - s1Len + 1;

            final detailLength = _selectedDisaster.isNotEmpty
                ? (OnboardingData.section2DisasterDetails[_selectedDisaster]?.length ?? 0)
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
