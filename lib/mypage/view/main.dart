import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/mypage/widget/myProfileWidget.dart';
import 'package:project_daon/mypage/widget/myPageAppBarWidget.dart';
import 'package:project_daon/mypage/widget/recoverydashboardWidget.dart';
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorStyles.main2, ColorStyles.main3],
          ),
        ),
        child: Column(
          children: [
            MyProfileWidget(name: name, level: level, disaster: disaster),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              width: double.infinity,
              child: ChecklistProgessBar(currentCheck: 58.9),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                clipBehavior: Clip.antiAlias,
                decoration: const ShapeDecoration(
                  color: ColorStyles.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RecoveryDashboardWidget(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '내 식물 확인하기',
                        style: FontStyles.med16.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '로그아웃',
                        style: FontStyles.med16.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '회원 탈퇴',
                        style: FontStyles.med16.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
