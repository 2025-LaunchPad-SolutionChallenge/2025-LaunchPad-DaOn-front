import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
import 'package:project_daon/ui/fontStyles.dart';
import 'roundToggleButton.dart';

class ExpandSectionWidget extends StatefulWidget {
  final String title;
  final List<String> options;
  final String hintText;
  final double hintSize;
  final bool isTextInput;

  const ExpandSectionWidget({
    super.key,
    required this.title,
    this.options = const ['테스트', '테스트'],
    this.hintText = '텍스트 입력',
    this.hintSize = 16.0,
    this.isTextInput = false,
  });

  @override
  State<ExpandSectionWidget> createState() => _ExpandSectionWidgetState();
}

class _ExpandSectionWidgetState extends State<ExpandSectionWidget> {
  String? _selectedOption; // 아무것도 선택되지 않은 상태를 위해 null 허용

  @override
  Widget build(BuildContext context) {
    return Theme(
      // ExpansionTile의 기본 위아래 테두리 선을 제거하기 위한 설정
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero, // 헤더 좌우 여백 제거
        title: Text(
          widget.title,
          style: FontStyles.semi16.copyWith(
            fontSize: 16.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (widget.isTextInput == false) ...[
            Container(
              width: double.infinity, // 왼쪽 정렬을 위해 넓이 확장
              padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
              child: Wrap(
                spacing: 8.0, // 버튼 간 가로 여백
                runSpacing: 10.0, // 줄바꿈 시 세로 여백
                children: widget.options.map((option) {
                  return RoundToggleButton(
                    title: option,
                    isSelected: _selectedOption == option,
                    onTap: () {
                      setState(() {
                        if (_selectedOption == option) {
                          _selectedOption = null;
                        } else {
                          _selectedOption = option;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            TextFieldWidget(
              hintText: widget.hintText,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value;
                });
              },
              hintSize: widget.hintSize,
            ),
          ],
        ],
      ),
    );
  }
}
