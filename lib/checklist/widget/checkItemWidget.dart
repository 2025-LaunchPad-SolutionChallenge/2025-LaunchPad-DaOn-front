import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';
import 'package:characters/characters.dart';

/// 1. 체크리스트 데이터를 관리할 모델 클래스
class ChecklistItemModel {
  final int checklistItemId;
  final bool isAiGenerated;
  String title;
  String? memo;
  List<String> imageUrls;
  bool isChecked;
  final int priority;
  final String? checklistDate;

  ChecklistItemModel({
    required this.checklistItemId,
    required this.isAiGenerated,
    required this.title,
    this.memo,
    this.imageUrls = const [],
    this.isChecked = false,
    this.priority = 2,
    this.checklistDate,
  });

  String get id => checklistItemId.toString();
}

/// 2. 개별 체크리스트 아이템 위젯
class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItemModel item;
  final Function(ChecklistItemModel) onOptionsTap;
  final ValueChanged<bool> onCheckChanged;

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
  bool _isExpanded = false;

  bool get _hasDetail {
    final hasMemo =
        widget.item.memo != null && widget.item.memo!.trim().isNotEmpty;

    final hasFiles = widget.item.imageUrls.isNotEmpty;

    return hasMemo || hasFiles;
  }

  void _toggleExpanded() {
    if (!_hasDetail) return;

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Color get _titleColor {
    return widget.item.isChecked
        ? ColorStyles.black2.withValues(alpha: 0.45)
        : ColorStyles.black2;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 체크박스
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
              ),

              const SizedBox(width: 8),

              // 2. 가운데 영역: AI 아이콘 + 텍스트
              Expanded(
                child: GestureDetector(
                  behavior: _hasDetail
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.deferToChild,
                  onTap: _hasDetail ? _toggleExpanded : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.isAiGenerated) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 15,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: _WordWrapText(
                          text: widget.item.title,
                          style: FontStyles.med14.copyWith(
                            color: _titleColor,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 3. 더보기 버튼 (...)
              SizedBox(
                width: 28,
                height: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.onOptionsTap(widget.item);
                  },
                  child: const Center(child: _SmallMoreIcon()),
                ),
              ),
            ],
          ),

          // 4. 펼쳐졌을 때 보이는 상세 영역
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded && _hasDetail
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 22.0,
                      top: 10.0,
                      bottom: 4.0,
                      right: 34.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //TODO: 메모 제목만 들어가는 공간. 없으면 해당 태그도 안보임
                        if (widget.item.memo != null &&
                            widget.item.memo!.trim().isNotEmpty)
                          _buildMemoArea(),

                        if (widget.item.memo != null &&
                            widget.item.memo!.trim().isNotEmpty &&
                            widget.item.imageUrls.isNotEmpty)
                          const SizedBox(height: 12),
                        //TODO: 이미지는 크기에 맞는 이미지가 들어가고, 파일일 경우 이미지를 최우선으로 표시하고 사진이 없을 때 파일이 있으면 그때는 파일을 미리보기로 파일 확장자에 따라 표시
                        if (widget.item.imageUrls.isNotEmpty) _buildFileArea(),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTag('Text'),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.item.memo!,
            softWrap: true,
            style: FontStyles.med14.copyWith(
              color: ColorStyles.black2,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTag('File'),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.imageUrls.take(3).map((url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      width: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ColorStyles.secon6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: FontStyles.med12.copyWith(color: ColorStyles.white, height: 1.2),
      ),
    );
  }
}

class _WordWrapText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _WordWrapText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final words = text.trim().split(RegExp(r'\s+'));

    return Wrap(
      spacing: 3,
      runSpacing: 2,
      children: words.map((word) {
        return Text(word, style: style);
      }).toList(),
    );
  }
}

class _SmallMoreIcon extends StatelessWidget {
  const _SmallMoreIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: ColorStyles.black2.withOpacity(0.55),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
