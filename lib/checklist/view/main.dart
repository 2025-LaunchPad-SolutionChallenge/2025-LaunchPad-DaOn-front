import 'package:flutter/material.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
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

  // UI 테스트를 위한 더미 데이터 리스트 생성
  List<ChecklistItemModel> dummyChecklists = [
    ChecklistItemModel(
      id: '1',
      isAiGenerated: true,
      title: '도움이 필요한 키워드 표시하기',
      memo: '오늘의 키워드 정리',
      imageUrls: [
        'https://picsum.photos/200', // 더미 이미지
        'https://picsum.photos/201',
        'https://picsum.photos/202',
        'https://picsum.photos/203', // 4번째 이미지는 최대 3개 제한에 의해 잘림
      ],
      isChecked: true, // 진한 녹색
    ),
    ChecklistItemModel(
      id: '2',
      isAiGenerated: true,
      title: '도움을 받을 수 있는 사람 / 기관 떠올리고 기록하기',
      isChecked: true,
    ),
    ChecklistItemModel(
      id: '3',
      isAiGenerated: false,
      title: '도움 받을 수 있는 청소 업체 알아보기',
      isChecked: false, // 연두색
    ),
  ];

  // 옵션(...) 팝업 띄우기 메서드 (데이터 전달)
  void _showItemOptionsBottomSheet(ChecklistItemModel selectedItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        // TODO: ItemBottomPopupWidget 생성자에 selectedItem을 넘겨주도록 수정해야 합니다.
        // 예: return ItemBottomPopupWidget(itemData: selectedItem);
        print('팝업에 넘길 데이터 아이디: ${selectedItem.id}, 제목: ${selectedItem.title}');
        return const ItemBottomPopupWidget();
      },
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
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 16.0),
                            itemCount: dummyChecklists.length,
                            itemBuilder: (context, index) {
                              return ChecklistItemWidget(
                                item: dummyChecklists[index],
                                // 체크박스 클릭 상태 변경 로직
                                onCheckChanged: (bool newValue) {
                                  setState(() {
                                    dummyChecklists[index].isChecked = newValue;
                                  });
                                },
                                // 더보기(...) 버튼 클릭 시 팝업으로 데이터 전달 로직
                                onOptionsTap: (ChecklistItemModel item) {
                                  _showItemOptionsBottomSheet(item);
                                },
                              );
                            },
                          ),
                        ),
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
