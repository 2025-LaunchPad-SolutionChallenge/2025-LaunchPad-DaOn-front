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
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      const ChecklistPage(),
      const CommunityPage(),
      const MyPage(),
    ];
  }

  void _onTapBottomNav(int index) {
    if (index == 0 && _currentIndex != 0) {
      _homeKey.currentState?.refreshTodayTasksFromOutside();
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
