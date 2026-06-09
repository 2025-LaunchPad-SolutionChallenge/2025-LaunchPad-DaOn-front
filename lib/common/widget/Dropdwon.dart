import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class Dropdown extends StatefulWidget {
  final List<String>? daonItemList;
  final List<String>? dateItemList;
  final String? color;
  final List<String>? items;
  final int? initialIndex;
  final ValueChanged<int>? onIndexChanged;

  const Dropdown({
    super.key,
    this.daonItemList,
    this.dateItemList,
    this.color,
    this.items,
    this.initialIndex,
    this.onIndexChanged,
  });

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  final List<String> _defaultItems = [
    '홍수 피해  |  2025 - 02 - 24',
    '태풍 피해  |  2025 - 08 - 12',
    '지진 피해  |  2025 - 11 - 05',
  ];

  List<String> _resolvedItems = [];
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _resolvedItems = widget.items ?? _defaultItems;
    _selectedValue = _resolvedItems.isNotEmpty
        ? _resolvedItems[(widget.initialIndex ?? 0).clamp(0, _resolvedItems.length - 1)]
        : null;
  }

  @override
  void didUpdateWidget(Dropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items || widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _resolvedItems = widget.items ?? _defaultItems;
        if (_resolvedItems.isEmpty) {
          _selectedValue = null;
        } else if (_selectedValue == null || !_resolvedItems.contains(_selectedValue)) {
          final idx = (widget.initialIndex ?? 0).clamp(0, _resolvedItems.length - 1);
          _selectedValue = _resolvedItems[idx];
        }
      });
    }
  }

  Color getColor() {
    if (widget.color == 'main1') {
      return ColorStyles.main1;
    } else {
      return ColorStyles.white;
    }
  }

  String getArrowColor() {
    if (widget.color == 'main1') {
      return 'assets/home/arrowGreen.svg';
    } else {
      return 'assets/home/arrow.svg';
    }
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
          color: getColor(), // 흰색 테두리 라인
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _resolvedItems.contains(_selectedValue) ? _selectedValue : null,
          style: FontStyles.med14.copyWith(color: getColor()),
          icon: Row(
            children: [
              SizedBox(width: 10.0),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SvgPicture.asset(getArrowColor()),
              ),
            ],
          ),
          iconSize: 24,
          isDense: true,
          dropdownColor: ColorStyles.main1,
          onChanged: (String? newValue) {
            if (newValue == null) return;
            setState(() => _selectedValue = newValue);
            final idx = _resolvedItems.indexOf(newValue);
            if (idx != -1) widget.onIndexChanged?.call(idx);
          },
          items: _resolvedItems.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}
