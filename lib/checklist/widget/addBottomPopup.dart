import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class AddBottomPopupWidget extends StatefulWidget {
  final String? initialTitle;
  final void Function(String title) onSubmit;

  const AddBottomPopupWidget({
    super.key,
    this.initialTitle,
    required this.onSubmit,
  });

  @override
  State<AddBottomPopupWidget> createState() => _AddBottomPopupWidgetState();
}

class _AddBottomPopupWidgetState extends State<AddBottomPopupWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.initialTitle != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: ShapeDecoration(
                  color: const Color(0x33525252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              _isEditMode ? '체크리스트 편집' : '체크리스트 추가',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            const SizedBox(height: 4.0),
            LineTextField(
              hintText: '원하는 체크리스트 내용을 입력해주세요!',
              maxLength: 20,
              controller: _controller,
            ),
            const SizedBox(height: 40.0),
            GradientButton(
              text: _isEditMode ? '수정하기' : '추가하기',
              onPressed: () {
                final title = _controller.text.trim();
                if (title.isNotEmpty) {
                  widget.onSubmit(title);
                }
              },
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
