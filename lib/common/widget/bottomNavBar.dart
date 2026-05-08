import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color activeColor = ColorStyles.main1;
  static const Color inactiveColor = ColorStyles.grey1;

  // 누를 때 퍼지는 색상
  static const Color navSplashColor = Color(0x1100AB7D);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: navSplashColor,
        highlightColor: Colors.transparent,
        hoverColor: navSplashColor,
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Pretendard',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Pretendard',
        ),
        items: _bottomNavItems.map((item) {
          final bool isSelected = currentIndex == item.index;

          return BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: isSelected ? 50 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                SvgPicture.asset(isSelected ? item.actIcon : item.inactIcon),
              ],
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavItem {
  final int index;
  final String actIcon;
  final String inactIcon;
  final String label;

  const BottomNavItem({
    required this.index,
    required this.actIcon,
    required this.inactIcon,
    required this.label,
  });
}

const _bottomNavItems = [
  BottomNavItem(
    index: 0,
    actIcon: 'assets/appbar/homeAct.svg',
    inactIcon: 'assets/appbar/home.svg',
    label: 'Home',
  ),
  BottomNavItem(
    index: 1,
    actIcon: 'assets/appbar/checklistAct.svg',
    inactIcon: 'assets/appbar/checklist.svg',
    label: 'Check List',
  ),
  BottomNavItem(
    index: 2,
    actIcon: 'assets/appbar/communityAct.svg',
    inactIcon: 'assets/appbar/community.svg',
    label: 'Community',
  ),
  BottomNavItem(
    index: 3,
    actIcon: 'assets/appbar/mypageAct.svg',
    inactIcon: 'assets/appbar/mypage.svg',
    label: 'MyPage',
  ),
];
