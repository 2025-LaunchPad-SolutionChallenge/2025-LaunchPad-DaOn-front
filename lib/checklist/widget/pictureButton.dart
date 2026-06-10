import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class PictureButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null이면 자동 비활성화
  final double? width; // null 허용 (기본값 infinity 처리)
  final double height; // 기본값 설정 예정

  const PictureButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width = 100.0,
    this.height = 57.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // 선택 여부에 따라 배경색과 글자색 반전
          backgroundColor: ColorStyles.secon5,
          foregroundColor: ColorStyles.main1,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: ColorStyles.main1,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: FontStyles.med14),
            // SizedBox(width: 6.0),
            // SvgPicture.asset('assets/checklist/camera_alt.svg'),
          ],
        ),
      ),
    );
  }
}
