import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동 비활성화
  final double? width; // null 허용 (기본값 infinity 처리)
  final double height; // 기본값 설정 예정

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width, // 명시하지 않으면 null
    this.height = 57.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDisabled
              ? [ColorStyles.secon3, ColorStyles.secon4]
              : [ColorStyles.main1, ColorStyles.main3], // 원하는 색상 조합
          begin: Alignment(0.02, -0.00),
          end: Alignment(1.00, 1.00),
        ),
        borderRadius: BorderRadius.circular(7), // 버튼과 동일한 곡률
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(text, style: FontStyles.semi16),
      ),
    );
  }
}
