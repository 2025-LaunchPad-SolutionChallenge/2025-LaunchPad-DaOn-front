import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class StartBlock extends StatelessWidget {
  final String? name;
  final String? myStep;
  final String? description;

  const StartBlock({
    super.key,
    this.name = "재현",
    this.myStep = "다시 움직임",
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final descText = description?.isNotEmpty == true
        ? description!
        : '오늘도 함께 회복해봐요!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요, $name 님\n$descText',
          style: FontStyles.semi20.copyWith(color: ColorStyles.white),
        ),
        SizedBox(height: 20.0),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorStyles.main1,
                borderRadius: BorderRadius.circular(7.0),
              ),
              child: Text(
                "${myStep}",
                style: FontStyles.semi28.copyWith(color: ColorStyles.white),
              ),
            ),
            SizedBox(width: 8.0),
            Text(
              "단계입니다.",
              style: FontStyles.semi20.copyWith(color: ColorStyles.white),
            ),
          ],
        ),
      ],
    );
  }
}
