import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBarWidget({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: SvgPicture.asset('assets/appbar/alarm.svg', width: 24),
                onPressed: () {
                  // 검색 기능 구현
                },
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/appbar/hamburger.svg',
                  width: 24,
                ),
                onPressed: () {
                  // 검색 기능 구현
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
