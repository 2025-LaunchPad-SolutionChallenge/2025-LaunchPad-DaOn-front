import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/mypage/widget/myProfileWidget.dart';
import 'package:project_daon/mypage/widget/mypageAppBarWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String name = '이재현';
  int level = 2;
  String disaster = '홍수';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MypageAppBarWidget(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.only(top: 100.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.00),
            end: Alignment(1.00, 0.71),
            colors: [ColorStyles.main2, ColorStyles.main3],
          ),
        ),
        child: Column(
          children: [
            MyProfileWidget(name: name, level: level, disaster: disaster),
          ],
        ),
      ),
    );
  }
}
