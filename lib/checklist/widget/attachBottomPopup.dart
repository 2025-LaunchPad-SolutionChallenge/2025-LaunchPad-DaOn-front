import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class AttachBottomPopupWidget extends StatefulWidget {
  final void Function(String title) onSubmit;

  const AttachBottomPopupWidget({super.key, required this.onSubmit});

  @override
  State<AttachBottomPopupWidget> createState() =>
      _AttachBottomPopupWidgetState();
}

class _AttachBottomPopupWidgetState extends State<AttachBottomPopupWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: ShapeDecoration(
                  color: const Color(0x33525252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            //TODO: 여기에 체크리스트 아이템(일반/AI) 상관 없이 목록화할 수 있는 기능 필요
            Dropdown(color: 'main1'),
            const SizedBox(height: 16.0),
            Text(
              '사진 / 파일 추가하기',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            const SizedBox(height: 4.0),
            //TODO: originalFileName를 작성하는 부분
            LineTextField(
              hintText: '제목을 입력해주세요!',
              maxLength: 20,
              controller: _controller,
            ),
            //TODO: 각 버튼을 클릭해서 사진이나 파일을 입력하고 나면, 버튼들은 없어지고 추가된 파일, 사진과 파일명이 보여짐. (실제로도 사진이나 피일이 있는 것.)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 112.0,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorStyles.white,
                          foregroundColor: ColorStyles.black2,
                          overlayColor: ColorStyles.main1,
                          disabledBackgroundColor: Colors.white,
                          disabledForegroundColor: ColorStyles.main1,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: BorderSide(
                              color: ColorStyles.main1,
                              width: 1.0,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/checklist/camera_alt.svg'),
                            const SizedBox(height: 8.0),
                            Text(
                              '사진',
                              style: FontStyles.med12.copyWith(
                                color: ColorStyles.black2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: SizedBox(
                      height: 112.0,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorStyles.white,
                          foregroundColor: ColorStyles.black2,
                          overlayColor: ColorStyles.main1,
                          disabledBackgroundColor: Colors.white,
                          disabledForegroundColor: ColorStyles.main1,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: BorderSide(
                              color: ColorStyles.main1,
                              width: 1.0,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/checklist/memo.svg'),
                            const SizedBox(height: 8.0),
                            Text(
                              '파일',
                              style: FontStyles.med12.copyWith(
                                color: ColorStyles.black2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //TODO: 추가를 누르면 명세에 맞게 request를 보낼 수 있게 되어야 함.
            const SizedBox(height: 40.0),
            GradientButton(
              text: '추가하기',
              onPressed: () {
                final title = _controller.text.trim();
                if (title.isNotEmpty) {
                  widget.onSubmit(title);
                }
              },
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
