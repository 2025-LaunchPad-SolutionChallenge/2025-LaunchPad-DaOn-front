import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPageDropdown extends StatelessWidget {
  final List<String> items; // 부모로부터 받을 드롭다운 리스트
  final String selectedValue; // 현재 선택된 값
  final ValueChanged<String?> onChanged; // 값이 변경될 때 실행될 함수
  final String? color;

  const MyPageDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.color,
  });

  Color getColor() {
    if (color == 'main1') {
      return ColorStyles.main1;
    } else {
      return ColorStyles.main2;
    }
  }

  String getArrowColor() {
    if (color == 'main1') {
      return 'assets/home/arrowGreen.svg';
    } else {
      return 'assets/home/arrow.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 2.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: getColor(), width: 1.0),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          style: FontStyles.med14.copyWith(color: getColor()),
          icon: Row(
            children: [
              const SizedBox(width: 10.0),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SvgPicture.asset(getArrowColor()),
              ),
            ],
          ),
          iconSize: 24,
          isDense: true,
          dropdownColor: ColorStyles.white,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}
