import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/buttonGroupManager.dart';
import 'package:project_daon/common/widget/greenBackButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';
import 'package:project_daon/onboarding/view/onboardingLocationConfirmPage.dart';
import 'package:project_daon/onboarding/widget/questionWidget.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
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
  final dynamic initialValue;
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
    this.initialValue,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<OnboardingType> createState() => _OnboardingTypeState();
}

class _OnboardingTypeState extends State<OnboardingType> {
  List<String>? _selectedOption;
  OnboardingLocation? _selectedLocation;

  late TextEditingController _textController;

  bool _isProgrammaticTextChange = false;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController();
    _applyInitialValue();

    _textController.addListener(_handleTextChanged);
  }

  void _applyInitialValue() {
    final initialValue = widget.initialValue;

    if (initialValue is OnboardingLocation) {
      _selectedLocation = initialValue;
      _textController.text = initialValue.displayAddress;
    } else if (initialValue is String) {
      _textController.text = initialValue;
    }
  }

  void _handleTextChanged() {
    if (_isProgrammaticTextChange) {
      setState(() {});
      return;
    }

    if (widget.onboardingType == 3 && _selectedLocation != null) {
      final currentText = _textController.text.trim();
      final selectedText = _selectedLocation!.displayAddress.trim();

      if (currentText != selectedText) {
        _selectedLocation = null;
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isNextEnabled {
    if (widget.onboardingType == 1 || widget.onboardingType == 4) {
      return _selectedOption != null && _selectedOption!.isNotEmpty;
    }

    if (widget.onboardingType == 3) {
      return _selectedLocation != null;
    }

    return _textController.text.trim().isNotEmpty;
  }

  Future<void> _openLocationConfirmPage() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.push<OnboardingLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingLocationConfirmPage(
          initialQuery: _textController.text.trim(),
        ),
      ),
    );

    if (!mounted || result == null) return;

    _isProgrammaticTextChange = true;
    _textController.text = result.displayAddress;
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
    _isProgrammaticTextChange = false;

    setState(() {
      _selectedLocation = result;
    });
  }

  dynamic _makeResult() {
    if (widget.onboardingType == 1 || widget.onboardingType == 4) {
      return _selectedOption;
    }

    if (widget.onboardingType == 3) {
      return _selectedLocation;
    }

    return _textController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
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
                    const SizedBox(height: 100.0),
                    Text(
                      widget.seconText ?? "",
                      style: FontStyles.med16.copyWith(
                        color: ColorStyles.main1,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    QuestionWidget(text: widget.question ?? ''),

                    if (widget.onboardingType == 1) ...[
                      const SizedBox(height: 70.0),
                      ButtonGroupManager(
                        options: widget.options ?? [],
                        isMultipleSelection:
                            widget.isMultipleSelection ?? false,
                        onChanged: (selectedList) {
                          setState(() {
                            _selectedOption = selectedList;
                          });
                        },
                      ),
                    ] else if (widget.onboardingType == 2) ...[
                      const SizedBox(height: 120.0),
                      TextFieldWidget(
                        hintText: widget.hintText!,
                        controller: _textController,
                      ),
                    ] else if (widget.onboardingType == 3) ...[
                      const SizedBox(height: 120.0),
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
                          const SizedBox(width: 10.0),
                          GreenBackButton(
                            text: widget.btnText!,
                            width: 80.0,
                            height: 48.0,
                            onPressed: _openLocationConfirmPage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedLocation == null
                            ? '검색 후 지도에서 위치를 인증해주세요.'
                            : '${_selectedLocation!.dong} 인증 완료',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedLocation == null
                              ? const Color(0xFF999999)
                              : ColorStyles.main1,
                        ),
                      ),
                    ] else if (widget.onboardingType == 4) ...[
                      const SizedBox(height: 70.0),
                      ButtonGroupManager(
                        options: widget.options ?? [],
                        isMultipleSelection:
                            widget.isMultipleSelection ?? false,
                        isGrid: true,
                        onChanged: (selectedList) {
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
                    const SizedBox(width: 10.0),
                  ],
                  Expanded(
                    child: GradientButton(
                      text: widget.totalPage == widget.currentPage
                          ? '저장하기'
                          : '다음',
                      onPressed: _isNextEnabled
                          ? () {
                              FocusScope.of(context).unfocus();
                              widget.onNext(_makeResult());
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
