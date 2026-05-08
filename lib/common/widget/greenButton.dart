import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class GreenButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동 비활성화
  final double? width; // null 허용 (기본값 infinity 처리)
  final double height; // 기본값 설정 예정

  const GreenButton({
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
          // 선택 여부에 따라 배경색과 글자색 반전
          backgroundColor: Colors.white,
          foregroundColor: ColorStyles.main1,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: ColorStyles.main1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(color: ColorStyles.main1, width: 1.0),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(text, style: FontStyles.semi16),
      ),
    );
  }
}
