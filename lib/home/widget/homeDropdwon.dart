import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class HomeDropdown extends StatefulWidget {
  final List<String>? daonItemList;
  final List<String>? dateItemList;
  final String? color;
  const HomeDropdown({
    super.key,
    this.daonItemList,
    this.dateItemList,
    this.color,
  });

  @override
  State<HomeDropdown> createState() => _HomeDropdownState();
}

class _HomeDropdownState extends State<HomeDropdown> {
  // 드롭다운에 표시될 모의 데이터 목록
  final List<String> _dropdownItems = [
    '홍수 피해  |  2025 - 02 - 24',
    '태풍 피해  |  2025 - 08 - 12',
    '지진 피해  |  2025 - 11 - 05',
  ];

  // 현재 선택된 아이템
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = _dropdownItems[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 내부 여백을 주어 텍스트와 테두리 사이의 간격을 만듭니다.
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 2.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: ColorStyles.white, // 흰색 테두리 라인
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedValue,
          style: FontStyles.med14.copyWith(color: ColorStyles.white),
          icon: Row(
            children: [
              SizedBox(width: 10.0),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SvgPicture.asset('assets/home/arrow.svg'),
              ),
            ],
          ),
          iconSize: 24,
          isDense: true,
          dropdownColor: ColorStyles.main1,
          onChanged: (String? newValue) {
            setState(() {
              _selectedValue = newValue!;
            });
          },
          items: _dropdownItems.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}
