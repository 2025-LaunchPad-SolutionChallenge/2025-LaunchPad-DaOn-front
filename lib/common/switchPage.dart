import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';

import '../home/view/main.dart';
import '../checklist/view/main.dart';
import '../community/view/main.dart';
import '../mypage/view/main.dart';

import 'widget/appBar.dart';
import 'widget/bottomNavBar.dart';

class SwitchPage extends StatefulWidget {
  const SwitchPage({super.key});

  @override
  State<SwitchPage> createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage> {
  int _currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<ChecklistPageState> _checklistKey =
      GlobalKey<ChecklistPageState>();
  final GlobalKey<MyPageState> _mypageKey = GlobalKey<MyPageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      ChecklistPage(key: _checklistKey),
      const CommunityPage(),
      MyPage(key: _mypageKey),
    ];
  }

  void _onTapBottomNav(int index) {
    if (index == 0 && _currentIndex != 0) {
      _homeKey.currentState?.refreshTodayTasksFromOutside();
    }
    if (index == 1 && _currentIndex != 1) {
      _checklistKey.currentState?.refreshWeeklyProgress();
    }
    if (index == 3 && _currentIndex != 3) {
      _mypageKey.currentState?.refreshRecoveryAndProgress();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorStyles.white,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTap: _onTapBottomNav,
      ),
    );
  }
}
