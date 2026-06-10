import 'package:flutter/material.dart';
import 'package:project_daon/ui/fontStyles.dart';
import '../../common/widget/progressBar.dart';

import 'package:project_daon/ui/colorStyles.dart';

class ChecklistProgessBar extends StatefulWidget {
  final double currentCheck;
  final Color? textcolor;
  final Color? progresscolor;
  final Color? backgroundcolor;

  ChecklistProgessBar({
    Key? key,
    required this.currentCheck,
    this.textcolor = ColorStyles.grey1,
    this.backgroundcolor = ColorStyles.grey2,
    this.progresscolor = ColorStyles.main1,
  }) : super(key: key);

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
            Text(
              '체크리스트 달성률',
              style: FontStyles.semi16.copyWith(color: ColorStyles.black2),
            ),
            SizedBox(width: 6.0),
            Text(
              '${progressMain}%',
              style: FontStyles.med15.copyWith(color: widget.textcolor),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10.0,
            backgroundColor: widget.backgroundcolor?.withAlpha(150),
            valueColor: AlwaysStoppedAnimation<Color>(widget.progresscolor!),
          ),
        ),
        SizedBox(height: 24.0),
      ],
    );
  }
}
