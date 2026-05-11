import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'AI 체크리스트 생성',
        style: FontStyles.semi16.copyWith(
          fontSize: 18,
          color: ColorStyles.black1,
        ),
      ),
      centerTitle: false,
      titleSpacing: 0.0,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(
          'assets/appbar/arrowBack.svg',
          width: 16,
          height: 16,
        ),
      ),
    );
  }
}
