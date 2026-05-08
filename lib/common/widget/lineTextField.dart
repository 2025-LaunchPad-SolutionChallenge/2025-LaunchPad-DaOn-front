import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class LineTextField extends StatefulWidget {
  final String hintText;
  final int? maxLength;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const LineTextField({
    Key? key,
    required this.hintText,
    this.maxLength,
    this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  State<LineTextField> createState() => _LineTextFieldState();
}

class _LineTextFieldState extends State<LineTextField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    // 부모 위젯에서 controller를 넘겨주면 그것을 쓰고, 없으면 내부에서 새로 생성
    _internalController = widget.controller ?? TextEditingController();
    _internalController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant LineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _internalController = widget.controller ?? TextEditingController();
      _internalController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _internalController.removeListener(_onTextChanged);
    // 내부에서 직접 만든 controller일 경우에만 메모리에서 해제
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool hasText = _internalController.text.isNotEmpty;

    return TextField(
      controller: _internalController,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      style: FontStyles.med16.copyWith(color: ColorStyles.main1),

      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) {
            if (maxLength == null) return null;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 8.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentLength',
                      style: FontStyles.med14.copyWith(
                        color: ColorStyles.grey1,
                      ),
                    ),
                    TextSpan(
                      text: ' / $maxLength',
                      style: FontStyles.med14.copyWith(
                        color: ColorStyles.black2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },

      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: FontStyles.med16.copyWith(color: ColorStyles.grey2),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: hasText ? ColorStyles.main1 : ColorStyles.grey1,
            width: 1.0,
          ),
        ),

        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ColorStyles.main1, width: 1.0),
        ),

        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
      ),

      // 커서 프리셋
      cursorColor: ColorStyles.main1,
      cursorWidth: 2.0,
      cursorHeight: 20.0,
      cursorRadius: const Radius.circular(2.0),
      cursorOpacityAnimates: true,
      obscureText: false,
    );
  }
}
