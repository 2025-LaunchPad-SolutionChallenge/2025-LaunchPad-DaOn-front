import 'package:flutter/material.dart';
import 'package:project_daon/ui/fontStyles.dart';
import '../../common/widget/progressBar.dart';

import 'package:project_daon/ui/colorStyles.dart';

class ChecklistProgessBar extends StatefulWidget {
  final double currentCheck;

  ChecklistProgessBar({Key? key, required this.currentCheck}) : super(key: key);

  @override
  State createState() => _ChecklistProgessBarState();
}

class _ChecklistProgessBarState extends State<ChecklistProgessBar> {
  @override
  Widget build(BuildContext context) {
    final double progress = widget.currentCheck / 100;
    final String progressMain = (progress * 100).toStringAsFixed(2);

    return Column(
      children: [
        Row(
          children: [
            Text('체크리스트 달성률', style: FontStyles.semi16),
            SizedBox(width: 6.0),
            Text(
              '${progressMain}%',
              style: FontStyles.med15.copyWith(color: ColorStyles.grey1),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10.0,
            backgroundColor: ColorStyles.grey2,
            valueColor: AlwaysStoppedAnimation<Color>(ColorStyles.main1),
          ),
        ),
        SizedBox(height: 24.0),
      ],
    );
  }
}
