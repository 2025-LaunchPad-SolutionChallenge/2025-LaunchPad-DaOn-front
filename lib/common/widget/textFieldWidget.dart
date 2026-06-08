import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class TextFieldWidget extends StatefulWidget {
  final String hintText;
  final double hintSize;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;

  const TextFieldWidget({
    Key? key,
    this.hintText = '',
    this.hintSize = 16.0,
    this.controller,
    this.onChanged,
    this.inputFormatters,
    this.keyboardType = TextInputType.multiline,
    this.maxLines = 3,
    this.minLines = 3,
  }) : super(key: key);

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant TextFieldWidget oldWidget) {
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
      onChanged: widget.onChanged, // onChanged 부모로 전달 추가

      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: FontStyles.med16.copyWith(
          color: ColorStyles.grey2,
          fontSize: widget.hintSize,
        ),

        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasText ? ColorStyles.main1 : ColorStyles.grey1,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(7.0), // 포커스 될 때와 곡률 통일
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorStyles.main1, width: 1.0),
          borderRadius: BorderRadius.circular(7.0),
        ),

        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 12.0,
        ),
      ),

      style: FontStyles.med16.copyWith(
        color: ColorStyles.main1,
        fontSize: widget.hintSize,
      ),

      // 커서 프리셋
      cursorColor: ColorStyles.main1,
      cursorWidth: 1.5,
      cursorHeight: 20.0,
      cursorRadius: const Radius.circular(2.0),
      cursorOpacityAnimates: true,
      obscureText: false,

      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      inputFormatters: widget.inputFormatters,
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
