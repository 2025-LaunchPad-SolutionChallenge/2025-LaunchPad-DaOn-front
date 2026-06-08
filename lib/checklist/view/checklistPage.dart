import 'package:flutter/material.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/itemBottomPopup.dart';
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
      isScrollControlled: true, // 키보드 대응이나 스크롤을 위해 유지
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return const ItemBottomPopupWidget();
      },
    );
  }

  void _showBottomSheet22() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 대응이나 스크롤을 위해 유지
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return const AddBottomPopupWidget();
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
                    // 0번 탭: 체크리스트
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 60.0),
                        Center(child: CheckNullWidget()),
                      ],
                    ),
                    // 1번 탭: 아카이빙
                    Column(
                      children: [
                        SizedBox(height: 60.0),
                        Text('아카이빙 페이지'),
                        ElevatedButton(
                          onPressed: () {
                            _showBottomSheet();
                          },
                          child: Text('버튼'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _showBottomSheet22();
                          },
                          child: Text('버튼'),
                        ),
                      ],
                    ),
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
