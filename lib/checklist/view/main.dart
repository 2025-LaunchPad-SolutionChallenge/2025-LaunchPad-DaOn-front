import 'package:flutter/material.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/itemBottomPopup.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/checklist/widget/pictureButton.dart';
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
        'https://picsum.photos/203',
        'https://picsum.photos/204',
      ],
      isChecked: true, // 진한 녹색
    ),
    ChecklistItemModel(
      id: '2',
      isAiGenerated: true,
      title: '도움을 받을 수 있는 사람 / 기관 떠올리고 기록하기',
      imageUrls: ['https://picsum.photos/205', 'https://picsum.photos/206'],
      isChecked: true,
    ),
    ChecklistItemModel(
      id: '3',
      isAiGenerated: false,
      title: '도움 받을 수 있는 청소 업체 알아보기',
      imageUrls: [
        'https://picsum.photos/205',
        'https://picsum.photos/206',
        'https://picsum.photos/206',
        'https://picsum.photos/206',
      ],
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

  // ----------------------------------------------------
  // 아카이브 탭 전용 헬퍼 메서드: 카테고리 타이틀 (세로줄 + 텍스트)
  // ----------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: ColorStyles.main2, // 메인 녹색
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            title,
            style: FontStyles.med16.copyWith(color: ColorStyles.black1),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 아카이브 탭 전용 헬퍼 메서드: 4열 이미지 그리드
  // ----------------------------------------------------
  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // SingleChildScrollView의 스크롤을 따름
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 1줄에 4개
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0), // 디자인에 맞춰 둥근 모서리 적용
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1번 탭의 'All' 섹션을 위해 모든 이미지 추출
    List<String> allImages = [];
    for (var item in dummyChecklists) {
      if (item.imageUrls.isNotEmpty) {
        allImages.addAll(item.imageUrls);
      }
    }

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
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChecklistProgessBar(currentCheck: 59.8),
              ChecklistWeekWidget(
                selectedDate: _currentSelectedDate,
                onDateSelected: (newDate) {
                  setState(() {
                    _currentSelectedDate = newDate;
                  });
                },
              ),
              const SizedBox(height: 20.0),

              TabBarWidget(
                selectedIndex: _selectedIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentSelectedDate.month}.${_currentSelectedDate.day}',
                      style: FontStyles.med20,
                    ),
                    if (_selectedIndex == 1)
                      PictureButton(
                        text: '등록하기',
                        onPressed: () {},
                        width: 112.0,
                        height: 33.0,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // -----------------------------
                    // 0번 탭: 체크리스트
                    // -----------------------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16.0),
                        if (dummyChecklists.isEmpty)
                          const Center(child: CheckNullWidget())
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: dummyChecklists.length,
                              itemBuilder: (context, index) {
                                return ChecklistItemWidget(
                                  item: dummyChecklists[index],
                                  onCheckChanged: (bool newValue) {
                                    setState(() {
                                      dummyChecklists[index].isChecked =
                                          newValue;
                                    });
                                  },
                                  onOptionsTap: (ChecklistItemModel item) {
                                    _showItemOptionsBottomSheet(item);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                    // -----------------------------
                    // 1번 탭: 아카이빙
                    // -----------------------------
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 테스트용 모달 버튼들 (요청하신 부분 그대로 유지)
                          ElevatedButton(
                            onPressed: () {
                              _showBottomSheet();
                            },
                            child: const Text('아카이빙 바텀시트 1'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _showBottomSheet22();
                            },
                            child: const Text('아카이빙 바텀시트 2'),
                          ),
                          const SizedBox(height: 16.0),

                          // 1. 메모 컴포넌트
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: ColorStyles.secon5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Memo', style: FontStyles.semi16),
                                const SizedBox(height: 12.0),
                                Text(
                                  '텍스트 정리하기', // 나중에 실제 메모 데이터로 바인딩
                                  style: FontStyles.med14.copyWith(
                                    color: ColorStyles.black2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          // 2. All 카테고리 갤러리 (이미지가 있을 때만 표시)
                          if (allImages.isNotEmpty) ...[
                            _buildSectionTitle('All'),
                            const SizedBox(height: 12.0),
                            _buildImageGrid(allImages),
                            const SizedBox(height: 32.0),
                          ],

                          // 3. 각 체크리스트 아이템별 갤러리
                          ...dummyChecklists
                              .where((item) => item.imageUrls.isNotEmpty)
                              .map((item) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle(item.title),
                                    const SizedBox(height: 12.0),
                                    _buildImageGrid(item.imageUrls),
                                    const SizedBox(height: 32.0), // 섹션 간 간격
                                  ],
                                );
                              })
                              .toList(),
                        ],
                      ),
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
