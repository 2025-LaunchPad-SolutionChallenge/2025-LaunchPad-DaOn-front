import 'package:flutter/material.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/common/widget/tapBarWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  DateTime _currentSelectedDate = DateTime.now();
  int _selectedIndex = 0;

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

  void _navigateToNewPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChecklistAiAddPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: AiChecklistFloatingButton(
                onPressed: () {
                  _navigateToNewPage();
                  // _showBottomSheet();
                },
              ),
            )
          : null,

      body: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChecklistProgessBar(currentCheck: 59.8),
              ChecklistWeekWidget(
                selectedDate: _currentSelectedDate,
                onDateSelected: (newDate) {
                  setState(() {
                    _currentSelectedDate = newDate;
                    print('Selected Date: ${_currentSelectedDate.toString()}');
                  });
                  // TODO: 새로운 날짜에 맞는 체크리스트 데이터 로드
                },
              ),
              SizedBox(height: 20.0),

              TabBarWidget(
                selectedIndex: _selectedIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),

              // 선택한 날짜 표시
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  '${_currentSelectedDate.month}.${_currentSelectedDate.day}',
                  style: FontStyles.med20,
                ),
              ),

              // 탭에 따라 바뀌는 화면
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 60.0),
                        Center(child: CheckNullWidget()),
                      ],
                    ),
                    Text('아카이빙 페이지'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
