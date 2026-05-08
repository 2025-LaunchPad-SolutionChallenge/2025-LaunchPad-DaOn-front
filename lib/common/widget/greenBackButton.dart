import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class GreenBackButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동 비활성화
  final double? width; // null 허용 (기본값 infinity 처리)
  final double height; // 기본값 설정 예정

  const GreenBackButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width, // 명시하지 않으면 null
    this.height = 57.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorStyles.main1,
          foregroundColor: ColorStyles.white,
          disabledBackgroundColor: ColorStyles.grey2,
          disabledForegroundColor: ColorStyles.white,
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
