import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/buttonGroupManager.dart';
import 'package:project_daon/common/widget/greenBackButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/onboarding/widget/questionWidget.dart';
import 'package:project_daon/onboarding/widget/textFieldWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';
import '../../common/widget/gradientButton.dart';
import '../../common/widget/greenButton.dart';
import '../../common/widget/progressBar.dart';

class OnboardingType extends StatefulWidget {
  final int? onboardingType;
  final String? question;
  final List<String>? options;
  final String? seconText;
  final String? hintText;
  final String? btnText;
  final int? num;
  final int? currentPage;
  final int? totalPage;
  final bool? isMultipleSelection;
  final VoidCallback? onPrevious;
  final Function(dynamic result) onNext;

  const OnboardingType({
    super.key,
    this.onboardingType = 1,
    this.question = '가입을 위한 정보를 \n입력해주세요.',
    this.options,
    this.seconText,
    this.hintText,
    this.btnText = '검색',
    this.num,
    this.currentPage = 1,
    this.totalPage = 1,
    this.isMultipleSelection,
    required this.onPrevious,
    required this.onNext,
  });

  State<OnboardingType> createState() => _OnboardingTypeState();
}

class _OnboardingTypeState extends State<OnboardingType> {
  List<String>? _selectedOption;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    print("🎨 현재 페이지 : ${widget.currentPage} / 최종 페이지 : ${widget.totalPage}");
    // 텍스트 입력 감지
    _textController = TextEditingController();
    _textController.addListener(() {
      setState(() {}); // 글자 입력마다 버튼 활성화 확인
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isNextEnabled {
    if (widget.onboardingType == 1) {
      return _selectedOption != null && _selectedOption!.isNotEmpty;
    } else {
      return _textController.text.trim().isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: 8.0,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgessBar(
                      currentStep: widget.currentPage! - 1,
                      totalStep: widget.totalPage! - 1,
                    ),
                    SizedBox(height: 100.0),
                    Text(
                      widget.seconText ?? "",
                      style: FontStyles.med16.copyWith(
                        color: ColorStyles.main1,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    QuestionWidget(text: widget.question ?? ''),
                    if (widget.onboardingType == 1) ...[
                      SizedBox(height: 70.0),
                      ButtonGroupManager(
                        options: widget.options ?? [],
                        isMultipleSelection:
                            widget.isMultipleSelection ?? false,
                        onChanged: (selectedList) {
                          print('현재 선택된 항목들: $selectedList');
                          setState(() {
                            _selectedOption = selectedList;
                          });
                        },
                      ),
                    ] else if (widget.onboardingType == 2) ...[
                      SizedBox(height: 120.0),
                      TextFieldWidget(
                        hintText: widget.hintText!,
                        controller: _textController,
                      ),
                    ] else if (widget.onboardingType == 3) ...[
                      SizedBox(height: 120.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LineTextField(
                              hintText: widget.hintText!,
                              maxLength: widget.num,
                              controller: _textController,
                            ),
                          ),
                          SizedBox(width: 10.0),
                          GreenBackButton(
                            text: widget.btnText!,
                            width: 80.0,
                            height: 48.0,
                            onPressed: () {
                              // 검색 로직
                            },
                          ),
                        ],
                      ),
                    ] else if (widget.onboardingType == 4) ...[
                      SizedBox(height: 70.0),
                      ButtonGroupManager(
                        options: widget.options ?? [],
                        isMultipleSelection:
                            widget.isMultipleSelection ?? false,
                        isGrid: true,
                        onChanged: (selectedList) {
                          print('현재 선택된 항목들: $selectedList');
                          setState(() {
                            _selectedOption = selectedList;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  if (widget.currentPage != 1) ...[
                    Expanded(
                      child: GreenButton(
                        text: '이전',
                        onPressed: widget.onPrevious,
                      ),
                    ),
                    SizedBox(width: 10.0),
                  ],
                  Expanded(
                    child: GradientButton(
                      text: widget.totalPage == widget.currentPage
                          ? '저장하기'
                          : '다음',
                      onPressed: _isNextEnabled
                          ? () {
                              FocusScope.of(context).unfocus(); // 키보드 닫기

                              dynamic result;
                              if (widget.onboardingType == 1) {
                                result = _selectedOption;
                              } else {
                                result = _textController.text;
                              }

                              widget.onNext(result);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
