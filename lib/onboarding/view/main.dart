import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/buttonGroupManager.dart';
import 'package:project_daon/common/widget/greenBackButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/onboarding/widget/questionWidget.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
import '../../common/widget/gradientButton.dart';
import '../../common/widget/greenButton.dart';
import '../../common/widget/progressBar.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' ')),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgessBar(currentStep: 3, totalStep: 5),
            QuestionWidget(text: '가입을 위한 정보를 \n입력해주세요.'),
            ButtonGroupManager(
              options: const [
                '아무 것도 못 했어요',
                '쉬는 시간을 가졌어요',
                '해야 할 일을 하나라도 했어요',
                '누군가와 대화를 했어요',
                '집 밖에 나갔어요',
              ],
              isMultipleSelection: false,
              onChanged: (selectedList) {
                print('현재 선택된 항목들: $selectedList');
              },
            ),
            TextFieldWidget(hintText: '이름을 입력해주세요.'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LineTextField(
                    hintText: '예) 연희동 132, 도산대로 33',
                    maxLength: 20,
                  ),
                ),
                SizedBox(width: 10.0),
                GreenBackButton(
                  text: '검색',
                  width: 80.0,
                  height: 48.0,
                  onPressed: () {
                    // 검색 로직
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: GreenButton(text: '이전', onPressed: () {}),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: GradientButton(text: '다음', onPressed: () {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
