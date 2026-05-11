import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class TabBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final List<String> tabTitles;

  const TabBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.tabTitles = const ['체크리스트', '아카이빙'],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildTabItem(title: '체크리스트', index: 0),
            _buildTabItem(title: '아카이빙', index: 1),
          ],
        ),
        Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 2, color: ColorStyles.main1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 탭 아이템 빌더 함수
  Widget _buildTabItem({required String title, required int index}) {
    bool isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque, // 빈 공간 클릭도 인식되도록 설정
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          alignment: Alignment.center,
          child: Text(
            title,
            style: FontStyles.semi16.copyWith(color: ColorStyles.black2),
          ),
        ),
      ),
    );
  }
}
