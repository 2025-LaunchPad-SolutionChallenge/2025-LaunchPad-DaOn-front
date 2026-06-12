import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/checklist/model/attachment_model.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class AttachmentItemBottomPopupWidget extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const AttachmentItemBottomPopupWidget({
    super.key,
    required this.attachment,
    required this.onEdit,
    required this.onDownload,
    required this.onDelete,
  });

  String get _displayTitle {
    if (attachment.attachmentType == 'MEMO') {
      return parseMemoTitle(attachment.content);
    }
    return attachment.originalFileName ?? '첨부';
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
              _displayTitle,
              style: FontStyles.semi16.copyWith(color: ColorStyles.black2),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
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
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: const BorderSide(
                              color: ColorStyles.main1,
                              width: 1.0,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onEdit,
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
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: SizedBox(
                      height: 112.0,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorStyles.white,
                          foregroundColor: ColorStyles.black2,
                          overlayColor: ColorStyles.main1,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: const BorderSide(
                              color: ColorStyles.main1,
                              width: 1.0,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onDelete,
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
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: const BorderSide(
                              color: ColorStyles.main1,
                              width: 1.0,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onDownload,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download_outlined,
                              color: ColorStyles.main1,
                              size: 26.0,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              '다운로드',
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
