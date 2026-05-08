import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';

class ProgessBar extends StatelessWidget {
  final int currentStep;
  final int totalStep;

  ProgessBar({Key? key, required this.currentStep, required this.totalStep})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progress = totalStep == 0 ? 0 : currentStep / totalStep;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10.0,
        backgroundColor: ColorStyles.grey2,
        valueColor: AlwaysStoppedAnimation<Color>(ColorStyles.main1),
      ),
    );
  }
}
