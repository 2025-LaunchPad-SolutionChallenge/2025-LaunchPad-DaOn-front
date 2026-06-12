import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/fontStyles.dart';
import '../../common/widget/progressBar.dart';
import 'package:project_daon/ui/colorStyles.dart';

class CheckNullWidget extends StatelessWidget {
  const CheckNullWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset('assets/checklist/checklist.svg'),
        SizedBox(height: 10.0),
        Text(
          'AI로 체크리스트를 생성해볼까요?',
          style: FontStyles.med16.copyWith(color: ColorStyles.black2),
        ),
        SizedBox(height: 20.0),
        Container(
          padding: EdgeInsets.fromLTRB(20.0, 16.0, 22.0, 16.0),
          decoration: BoxDecoration(
            color: ColorStyles.secon1,
            borderRadius: BorderRadius.circular(7.0),
          ),
          child: Column(
            children: [
              Text(
                '•   입력한 내용을 바탕으로 할 일을 자동으로 정리해줘요.',
                style: FontStyles.med12.copyWith(color: ColorStyles.black2),
              ),
              SizedBox(height: 6.0),
              Text(
                '•   지금 상황에 맞는 우선순위를 추천해줘요.',
                style: FontStyles.med12.copyWith(color: ColorStyles.black2),
              ),
              SizedBox(height: 6.0),
              Text(
                '•   오늘 · 이번 주 체크리스트로 나눠서 보여줘요.',
                style: FontStyles.med12.copyWith(color: ColorStyles.black2),
              ),
            ],
          ),
        ),
        SizedBox(height: 100.0),
      ],
    );
  }
}
