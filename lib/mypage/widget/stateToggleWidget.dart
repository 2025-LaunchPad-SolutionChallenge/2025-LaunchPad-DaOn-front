import 'package:flutter/material.dart';
import 'package:project_daon/mypage/model/disasterRecord.dart';
import 'package:project_daon/ui/fontStyles.dart';
import 'package:project_daon/ui/colorStyles.dart';

class StateToggleWidget extends StatelessWidget {
  final RecoveryStatus currentStatus;
  final ValueChanged<RecoveryStatus> onStatusChanged;

  const StateToggleWidget({
    Key? key,
    required this.currentStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  Widget _buildOption(String text, RecoveryStatus status) {
    final isSelected = currentStatus == status;
    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: Text(
        text,
        style: FontStyles.med14.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? ColorStyles.main2 : ColorStyles.grey1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption('회복 중', RecoveryStatus.recovering),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: Text('|', style: TextStyle(color: ColorStyles.grey1)),
        ),
        _buildOption('회복 완료', RecoveryStatus.completed),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: Text('|', style: TextStyle(color: ColorStyles.grey1)),
        ),
        _buildOption('보관', RecoveryStatus.archived),
      ],
    );
  }
}
