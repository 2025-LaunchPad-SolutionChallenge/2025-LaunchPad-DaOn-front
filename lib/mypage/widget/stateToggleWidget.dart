import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

// currentStatus: '전체' | 'ACTIVE' | 'EXPIRED' | 'ARCHIVED'
// UI 레이블: 전체 | 회복 중 | 회복 완료 | 보관
class StateToggleWidget extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusChanged;

  const StateToggleWidget({
    Key? key,
    required this.currentStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  static const List<List<String>> _options = [
    ['전체', '전체'],
    ['ACTIVE', '회복 중'],
    ['EXPIRED', '회복 완료'],
    ['ARCHIVED', '보관'],
  ];

  Widget _buildOption(String code, String label) {
    final isSelected = currentStatus == code;
    return GestureDetector(
      onTap: () => onStatusChanged(code),
      child: Text(
        label,
        style: FontStyles.med14.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? ColorStyles.main2 : ColorStyles.grey1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < _options.length; i++) {
      if (i > 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text('|', style: TextStyle(color: ColorStyles.grey1)),
          ),
        );
      }
      children.add(_buildOption(_options[i][0], _options[i][1]));
    }
    return Row(children: children);
  }
}
