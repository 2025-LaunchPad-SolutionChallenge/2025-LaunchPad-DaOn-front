import 'package:flutter/material.dart';
import 'package:project_daon/ui/fontStyles.dart';
import '../../common/widget/progressBar.dart';

import 'package:project_daon/ui/colorStyles.dart';

class ChecklistProgessBar extends StatefulWidget {
  final double currentCheck;
  final String? text;
  final Color? textcolor;
  final Color? text2color;
  final Color? progresscolor;
  final Color? backgroundcolor;

  ChecklistProgessBar({
    Key? key,
    required this.currentCheck,
    this.text = '체크리스트 달성률',
    this.textcolor = ColorStyles.grey1,
    this.text2color,
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
    final String progressMain = (progress * 100).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.text.toString(),
              style: FontStyles.semi16.copyWith(
                color: widget.text2color ?? ColorStyles.black2.withAlpha(180),
              ),
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
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.progresscolor!.withAlpha(180),
            ),
          ),
        ),
        SizedBox(height: 24.0),
      ],
    );
  }
}
