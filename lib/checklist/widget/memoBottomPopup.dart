import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MemoAttachBottomPopupWidget extends StatefulWidget {
  final void Function(String title) onSubmit;

  const MemoAttachBottomPopupWidget({super.key, required this.onSubmit});

  @override
  State<MemoAttachBottomPopupWidget> createState() =>
      _MemoAttachBottomPopupWidgetState();
}

class _MemoAttachBottomPopupWidgetState
    extends State<MemoAttachBottomPopupWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            //TODO: 여기에 체크리스트 아이템(일반/AI) 상관 없이 목록화할 수 있는 기능 필요
            Dropdown(color: 'main1'),
            const SizedBox(height: 16.0),
            Text(
              '메모 등록하기',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            const SizedBox(height: 4.0),
            //TODO: 제목을 입력할 수 있음. > 단, 일반 텍스트와 합쳐서 보내지는데 제목은 '## '으로 표시하여 아카이빙에 제목과 텍스트를 분리해서 표시할 수 있도록 할 것.
            LineTextField(
              hintText: '제목을 입력해주세요!',
              maxLength: 20,
              controller: _controller,
            ),
            //TODO: 일반 텍스트를 입력할 수 있음. > -나 - [ ]를 인식할 수 있게 해서 사용자가 좀 더 내용을 보기 쉽게 만들 것임.
            _buildTextFieldForType2(),
            const SizedBox(height: 40.0),
            GradientButton(
              text: '추가하기',
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

  //TODO: 아직 다른 화면에서 가지고 온 위젯이라 fit한 위젯이 아님. 그러므로 해당 포맷을 활용하되, popup에서 이용할 수 있도록 구성할 것.
  Widget _buildTextFieldForType2() {
    const tallPadding = EdgeInsets.only(
      top: 12.0,
      bottom: 60.0,
      right: 12.0,
      left: 12.0,
    );

    return TextFieldWidget(
      hintText: widget.hintText ?? '',
      controller: _textController,
      inputFormatters: [
        _NoNewlineFormatter(),
        if (widget.num != null) LengthLimitingTextInputFormatter(widget.num),
      ],
      keyboardType: TextInputType.text,
      maxLines: 1,
      minLines: 1,
      contentPadding: tallPadding,
    );
  }
}
