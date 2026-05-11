import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyProfileWidget extends StatelessWidget {
  final String name;
  final int level;
  final String disaster;

  const MyProfileWidget({
    super.key,
    required this.name,
    required this.level,
    required this.disaster,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240.0,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/mypage/myprofile.svg'),
          SizedBox(height: 16.0),
          Text(
            '${name} / Lv. ${level.toString()} / ${disaster}',
            style: FontStyles.semi20.copyWith(color: ColorStyles.white),
          ),
        ],
      ),
    );
  }
}
