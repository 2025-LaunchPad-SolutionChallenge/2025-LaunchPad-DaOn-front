import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/checklist/model/attachment_model.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistItemModel {
  final int checklistItemId;
  final bool isAiGenerated;
  String title;
  String? memo;
  List<String> imageUrls;
  bool isChecked;
  final int priority;
  final String? checklistDate;
  final Map<String, int>? attachmentSummary;

  ChecklistItemModel({
    required this.checklistItemId,
    required this.isAiGenerated,
    required this.title,
    this.memo,
    this.imageUrls = const [],
    this.isChecked = false,
    this.priority = 2,
    this.checklistDate,
    this.attachmentSummary,
  });

  String get id => checklistItemId.toString();
}

class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItemModel item;
  final Function(ChecklistItemModel) onOptionsTap;
  final ValueChanged<bool> onCheckChanged;
  final Future<List<AttachmentModel>> Function()? onFetchAttachments;
  final void Function(AttachmentModel)? onAttachmentLongPress;

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onOptionsTap,
    required this.onCheckChanged,
    this.onFetchAttachments,
    this.onAttachmentLongPress,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  bool _isExpanded = false;
  List<AttachmentModel>? _attachments;
  bool _isFetchingAttachments = false;

  bool get _hasDetail {
    final s = widget.item.attachmentSummary;
    if (s != null) {
      return (s['MEMO'] ?? 0) > 0 ||
          (s['IMAGE'] ?? 0) > 0 ||
          (s['FILE'] ?? 0) > 0;
    }
    return (widget.item.memo?.trim().isNotEmpty ?? false) ||
        widget.item.imageUrls.isNotEmpty;
  }

  void _toggleExpanded() {
    if (!_hasDetail) return;
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded &&
        _attachments == null &&
        !_isFetchingAttachments &&
        widget.onFetchAttachments != null) {
      _fetchAttachments();
    }
  }

  Future<void> _fetchAttachments() async {
    setState(() => _isFetchingAttachments = true);
    try {
      final result = await widget.onFetchAttachments!();
      if (mounted) {
        setState(() {
          _attachments = result;
          _isFetchingAttachments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingAttachments = false);
    }
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
                    child: _buildExpandedArea(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedArea() {
    if (_isFetchingAttachments) {
      return const Padding(
        padding: EdgeInsets.only(top: 4.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_attachments != null) {
      final memos = _attachments!
          .where((a) => a.attachmentType == 'MEMO')
          .toList();
      final files = _attachments!
          .where((a) => a.attachmentType != 'MEMO')
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memos.isNotEmpty) _buildFetchedMemoArea(memos.first),
          if (memos.isNotEmpty && files.isNotEmpty) const SizedBox(height: 12),
          if (files.isNotEmpty) _buildFetchedFileArea(files),
        ],
      );
    }

    // legacy fallback
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.item.memo != null && widget.item.memo!.trim().isNotEmpty)
          _buildLegacyMemoArea(),
        if (widget.item.memo != null &&
            widget.item.memo!.trim().isNotEmpty &&
            widget.item.imageUrls.isNotEmpty)
          const SizedBox(height: 12),
        if (widget.item.imageUrls.isNotEmpty) _buildLegacyFileArea(),
      ],
    );
  }

  Widget _buildFetchedMemoArea(AttachmentModel memo) {
    return GestureDetector(
      onLongPress: widget.onAttachmentLongPress != null
          ? () => widget.onAttachmentLongPress!(memo)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTag('Text'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parseMemoTitle(memo.content),
              softWrap: true,
              style: FontStyles.med14.copyWith(
                color: ColorStyles.black2,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchedFileArea(List<AttachmentModel> files) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTag('File'),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: files.take(3).map((f) {
              return GestureDetector(
                onLongPress: widget.onAttachmentLongPress != null
                    ? () => widget.onAttachmentLongPress!(f)
                    : null,
                child: _buildFilePreview(f),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview(AttachmentModel attachment) {
    if (attachment.attachmentType == 'IMAGE') {
      final url = attachment.thumbnailUrl ?? attachment.fileUrl;
      if (url != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fileNameBox(attachment.originalFileName),
          ),
        );
      }
      return _fileNameBox(attachment.originalFileName);
    }
    return _buildFileThumbnailBox(attachment);
  }

  Widget _buildFileThumbnailBox(AttachmentModel attachment) {
    final ext = (attachment.originalFileName ?? '')
        .split('.')
        .last
        .toLowerCase();
    final svgAsset =
        ['doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)
        ? 'assets/checklist/doc.png'
        : 'assets/checklist/pdf.png';
    return Container(
      width: 88,
      height: 88,
      child: Center(child: Image(image: AssetImage(svgAsset))),
    );
  }

  Widget _fileNameBox(String? name) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: ColorStyles.secon5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: ColorStyles.black2,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildLegacyMemoArea() {
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

  Widget _buildLegacyFileArea() {
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
