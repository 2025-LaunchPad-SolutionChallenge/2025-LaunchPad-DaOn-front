import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class YellowBackButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동 비활성화
  final double? width; // null 허용 (기본값 infinity 처리)
  final double height; // 기본값 설정 예정

  const YellowBackButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 57.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorStyles.secon2,
          foregroundColor: ColorStyles.main1,
          disabledBackgroundColor: ColorStyles.grey2,
          disabledForegroundColor: ColorStyles.main1,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(text, style: FontStyles.semi16),
      ),
    );
  }
}
