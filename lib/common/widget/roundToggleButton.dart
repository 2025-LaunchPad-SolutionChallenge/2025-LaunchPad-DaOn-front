import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class RoundToggleButton extends StatefulWidget {
  final String title;
  final double fontSize;
  final bool isSelected;
  final VoidCallback onTap;

  const RoundToggleButton({
    super.key,
    required this.title,
    this.fontSize = 14.0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<RoundToggleButton> createState() => _RoundToggleButtonState();
}

class _RoundToggleButtonState extends State<RoundToggleButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          // 선택 시 메인 색상(녹색 계열 가정), 미선택 시 흰색 배경
          color: widget.isSelected ? ColorStyles.main1 : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: ColorStyles.main1, // 미선택 상태에서도 테두리는 메인 색상 유지
            width: 1.0,
          ),
        ),
        child: Text(
          widget.title,
          style: FontStyles.semi16.copyWith(
            fontSize: widget.fontSize,
            color: widget.isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
