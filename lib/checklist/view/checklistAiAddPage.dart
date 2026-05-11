import 'package:flutter/material.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/common/widget/DetailAppBar.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/common/widget/expandSectionWidget.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/tapBarWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistAiAddPage extends StatefulWidget {
  const ChecklistAiAddPage({super.key});

  @override
  State<ChecklistAiAddPage> createState() => _ChecklistAiAddPageState();
}

class _ChecklistAiAddPageState extends State<ChecklistAiAddPage> {
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 300, // 우선 임시 높이 지정
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: ShapeDecoration(
                    color: const Color(0x33525252),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  '여기에 두 번째 이미지의 세부 위젯들을 추가하세요.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorStyles.white,
      appBar: DetailAppBar(),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나의 재난',
                      style: FontStyles.semi16.copyWith(
                        color: ColorStyles.black2,
                      ),
                    ),
                    SizedBox(height: 6.0),
                    Dropdown(color: 'main1'),
                    SizedBox(height: 16.0),
                    Text(
                      '재난 상황을 입력해주세요.\n상황에 맞춰서 AI가 체크리스트를 생성합니다.',
                      style: FontStyles.med15.copyWith(
                        color: ColorStyles.black2,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    ExpandSectionWidget(
                      title: '오늘 외출 가능 여부',
                      options: ['가능', '불가능'],
                    ),
                    ExpandSectionWidget(
                      title: '외출 가능 시간',
                      options: ['10분', '30분', '1시간 이상'],
                    ),
                    ExpandSectionWidget(
                      title: '특이 사항 입력',
                      isTextInput: true,
                      hintText: '특이 사항을 입력해주세요.',
                      hintSize: 14.0,
                    ),
                  ],
                ),
              ),
              GradientButton(text: '생성하기'),
            ],
          ),
        ),
      ),
    );
  }
}
