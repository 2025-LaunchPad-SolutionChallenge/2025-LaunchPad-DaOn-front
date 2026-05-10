import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class AiChecklistFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AiChecklistFloatingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          backgroundColor: ColorStyles.main1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          'AI 체크리스트 생성',
          style: FontStyles.semi16.copyWith(
            color: ColorStyles.white,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
}
