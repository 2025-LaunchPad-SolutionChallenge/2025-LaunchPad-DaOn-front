import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/greenButton.dart';
import 'package:project_daon/common/widget/progressBar.dart';
import 'package:project_daon/common/widget/selectableButton.dart';
import 'package:project_daon/home/api/dailyStatusApi.dart';
import 'package:project_daon/home/model/dailyStatusData.dart';
import 'package:project_daon/home/model/dailyStatusQuestion.dart';
import 'package:project_daon/onboarding/widget/questionWidget.dart';

class DailyStatusCheckPage extends StatefulWidget {
  const DailyStatusCheckPage({super.key});

  @override
  State<DailyStatusCheckPage> createState() => _DailyStatusCheckPageState();
}

class _DailyStatusCheckPageState extends State<DailyStatusCheckPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  // 각 페이지의 선택 결과를 컨트롤러에서 직접 관리 → 뒤로 갔다 와도 선택이 유지됨
  final Map<int, List<String>> _answers = {};
  bool _isSubmitting = false;

  final List<DailyStatusQuestion> _questions = DailyStatusData.questions;

  // "아무 것도 못 했어요"는 배타적 선택지
  static const String _exclusiveActivity = '아무 것도 못 했어요';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(int pageIndex, String option) {
    setState(() {
      final question = _questions[pageIndex];
      final current = List<String>.from(_answers[pageIndex] ?? []);

      if (!question.isMultipleSelection) {
        _answers[pageIndex] = current.contains(option) ? [] : [option];
        return;
      }

      // 다중 선택: "아무 것도 못 했어요" 배타 처리
      if (option == _exclusiveActivity) {
        _answers[pageIndex] = current.contains(option) ? [] : [_exclusiveActivity];
      } else {
        if (current.contains(option)) {
          current.remove(option);
        } else {
          current.remove(_exclusiveActivity);
          current.add(option);
        }
        _answers[pageIndex] = current;
      }
    });
  }

  bool _isPageValid(int pageIndex) {
    return (_answers[pageIndex] ?? []).isNotEmpty;
  }

  // score 매핑은 한 곳에서만 계산
  int _computeScore(int questionIndex) {
    final question = _questions[questionIndex];
    final selected = _answers[questionIndex] ?? [];

    if (question.scoreField == 'activityScore') {
      if (selected.contains(_exclusiveActivity)) return 1;
      return (selected.length + 1).clamp(1, 5);
    }

    if (selected.isEmpty) return 1;
    return (question.options.indexOf(selected.first) + 1).clamp(1, 5);
  }

  Future<void> _handleNext() async {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submit();
    }
  }

  void _handlePrevious() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final emotionScore = _computeScore(0);
    final energyScore = _computeScore(1);
    final activityScore = _computeScore(2);
    final recoveryScore = _computeScore(3);
    final needScore = _computeScore(4);

    debugPrint(
      '[상태체크] 최종 요청 본문: { '
      'emotionScore: $emotionScore, energyScore: $energyScore, '
      'activityScore: $activityScore, recoveryScore: $recoveryScore, '
      'needScore: $needScore }',
    );

    try {
      final result = await DailyStatusApi().submitDailyStatus(
        emotionScore: emotionScore,
        energyScore: energyScore,
        activityScore: activityScore,
        recoveryScore: recoveryScore,
        needScore: needScore,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.message} (총점: ${result.totalScore})')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _questions.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final question = _questions[index];
          final selected = _answers[index] ?? [];
          final isLast = index == _questions.length - 1;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 24.0,
                bottom: 8.0,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProgessBar(
                            currentStep: index,
                            totalStep: _questions.length - 1,
                          ),
                          const SizedBox(height: 100.0),
                          QuestionWidget(text: question.question),
                          const SizedBox(height: 70.0),
                          ...question.options.map((option) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: SelectableButton(
                              text: option,
                              isSelected: selected.contains(option),
                              onPressed: () => _handleOptionSelected(index, option),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      if (index > 0) ...[
                        Expanded(
                          child: GreenButton(
                            text: '이전',
                            onPressed: _handlePrevious,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                      ],
                      Expanded(
                        child: GradientButton(
                          text: isLast
                              ? (_isSubmitting ? '저장 중...' : '저장하기')
                              : '다음',
                          onPressed: (_isPageValid(index) && !_isSubmitting)
                              ? _handleNext
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
