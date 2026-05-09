import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class SemiCircleProgressBar extends StatelessWidget {
  final double percentage; // 0.0 ~ 1.0 사이의 값 (예: 47% -> 0.47)
  const SemiCircleProgressBar({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 0.5,
      child: CircularPercentIndicator(
        radius: 110.0,
        lineWidth: 37.0,
        percent: percentage,
        arcType: ArcType.HALF,
        arcBackgroundColor: ColorStyles.grey2,
        progressColor: ColorStyles.main1,
        circularStrokeCap: CircularStrokeCap.butt,

        animation: true,
        animationDuration: 300,

        center: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: FontStyles.semi28.copyWith(
              fontSize: 32,
              color: ColorStyles.white,
            ),
          ),
        ),
      ),
    );
  }
}
