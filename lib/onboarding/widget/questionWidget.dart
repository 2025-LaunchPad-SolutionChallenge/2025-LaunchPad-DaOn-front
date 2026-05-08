import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class QuestionWidget extends StatelessWidget {
  final String text;

  const QuestionWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FontStyles.semi24.copyWith(
        color: ColorStyles.black2,
        letterSpacing: -0.33,
      ),
    );
  }
}
