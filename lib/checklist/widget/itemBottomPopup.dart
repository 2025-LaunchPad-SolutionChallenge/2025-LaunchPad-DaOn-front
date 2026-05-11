import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ItemBottomPopupWidget extends StatelessWidget {
  final String title;

  const ItemBottomPopupWidget({super.key, this.title = '도움이 필요한 키워드 표시하기'});

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
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: ShapeDecoration(
                color: const Color(0x33525252),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              title,
              style: FontStyles.semi16.copyWith(color: ColorStyles.black2),
            ),
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
                            SvgPicture.asset('assets/checklist/edit.svg'),
                            const SizedBox(height: 8.0),
                            Text(
                              '편집하기',
                              style: FontStyles.med12.copyWith(
                                color: ColorStyles.black2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
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
                            SvgPicture.asset('assets/checklist/del.svg'),
                            const SizedBox(height: 8.0),
                            Text(
                              '삭제하기',
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
                              '메모하기',
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
          ],
        ),
      ),
    );
  }
}
