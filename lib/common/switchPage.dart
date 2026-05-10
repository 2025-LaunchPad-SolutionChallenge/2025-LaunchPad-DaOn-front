import 'package:flutter/material.dart';

import '../home/view/main.dart';
import '../check/view/main.dart';
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

  final List<Widget> _pages = const [
    HomePage(),
    CheckPage(),
    CommunityPage(),
    MyPage(),
  ];

  void _onTapBottomNav(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTap: _onTapBottomNav,
      ),
    );
  }
}
