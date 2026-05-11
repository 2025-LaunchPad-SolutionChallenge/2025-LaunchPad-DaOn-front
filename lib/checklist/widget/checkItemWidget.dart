import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

/// 1. 체크리스트 데이터를 관리할 모델 클래스
class ChecklistItemModel {
  final String id;
  final bool isAiGenerated; // AI 생성 여부 (제미나이 로고 표시용)
  String title;
  String? memo; // 상세 텍스트 제목
  List<String> imageUrls; // 파일 경로 또는 URL
  bool isChecked;

  ChecklistItemModel({
    required this.id,
    required this.isAiGenerated,
    required this.title,
    this.memo,
    this.imageUrls = const [],
    this.isChecked = false,
  });
}

/// 2. 개별 체크리스트 아이템 위젯
class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItemModel item;
  final Function(ChecklistItemModel)
  onOptionsTap; // '...' 버튼 클릭 시 팝업에 데이터를 넘겨주기 위한 콜백
  final ValueChanged<bool> onCheckChanged; // 체크 상태 변경 콜백

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onOptionsTap,
    required this.onCheckChanged,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  bool _isExpanded = false; // 아코디언 펼침 여부

  @override
  Widget build(BuildContext context) {
    // 임시 색상 (ColorStyles.main2, secon5를 대체)
    final Color main2 = const Color(0xFF5CAE8B);
    final Color secon5 = const Color(0xFFB5E3C5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 체크박스 (on/off 불린 값 관리)
            GestureDetector(
              onTap: () {
                widget.onCheckChanged(!widget.item.isChecked);
              },
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: widget.item.isChecked
                      ? ColorStyles.main2
                      : ColorStyles.secon5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 2. 가운데 영역 (로고 + 텍스트) - 누르면 펼쳐짐
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  children: [
                    if (widget.item.isAiGenerated) ...[
                      // AI 제미나이 로고 (아이콘으로 대체, 실제 에셋이 있다면 Image.asset 사용)
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: FontStyles.med14.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 더보기 버튼 (...)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // 부모 위젯으로 아이템 데이터 전달
                widget.onOptionsTap(widget.item);
              },
            ),
          ],
        ),

        // 4. 펼쳐졌을 때 보이는 상세 영역 (Text & File)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 22.0,
                    top: 12.0,
                    bottom: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 메모 영역
                      if (widget.item.memo != null &&
                          widget.item.memo!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTag('Text'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.memo!,
                                style: FontStyles.med14.copyWith(
                                  color: ColorStyles.black2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // 파일 영역 (최대 3개)
                      if (widget.item.imageUrls.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTag('File'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.item.imageUrls.take(3).map((
                                  url,
                                ) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      url,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16), // 아이템 간 간격
      ],
    );
  }

  // Text, File 태그 위젯 생성 헬퍼 메서드
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFA2DABF), // 이미지상의 밝은 민트색
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: FontStyles.med12.copyWith(color: ColorStyles.white),
      ),
    );
  }
}
