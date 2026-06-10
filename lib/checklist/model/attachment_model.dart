class AttachmentModel {
  final int attachmentId;
  final int? checklistItemId;
  final String? checklistItemTitle;
  final String attachmentType; // 'MEMO' | 'IMAGE' | 'FILE'
  final String? content;
  final String? fileUrl;
  final String? originalFileName;
  final String? mimeType;
  final int? fileSize;
  final String? thumbnailUrl;
  final String? checklistDate;
  final String? createdAt;

  const AttachmentModel({
    required this.attachmentId,
    this.checklistItemId,
    this.checklistItemTitle,
    required this.attachmentType,
    this.content,
    this.fileUrl,
    this.originalFileName,
    this.mimeType,
    this.fileSize,
    this.thumbnailUrl,
    this.checklistDate,
    this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      attachmentId: (json['attachmentId'] as num?)?.toInt() ?? 0,
      checklistItemId: (json['checklistItemId'] as num?)?.toInt(),
      checklistItemTitle: json['checklistItemTitle']?.toString(),
      attachmentType: json['attachmentType']?.toString() ?? 'MEMO',
      content: json['content']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      originalFileName: json['originalFileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      checklistDate: json['checklistDate']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

String parseMemoTitle(String? content) {
  if (content == null || content.isEmpty) return '메모';
  if (content.startsWith('## ')) {
    final idx = content.indexOf('\n');
    if (idx == -1) return content.substring(3).trim();
    return content.substring(3, idx).trim();
  }
  return '메모';
}

String parseMemoBody(String? content) {
  if (content == null || content.isEmpty) return '';
  if (content.startsWith('## ')) {
    final idx = content.indexOf('\n');
    if (idx == -1 || idx == content.length - 1) return '';
    return content.substring(idx + 1);
  }
  return content;
}

String buildMemoContent(String title, String body) => '## $title\n$body';

bool isOver10Mb(int sizeBytes) => sizeBytes > 10 * 1024 * 1024;

class ChecklistArchiveGroup {
  final int checklistItemId;
  final String checklistItemTitle;
  final AttachmentModel? memo;
  final List<AttachmentModel> images;
  final List<AttachmentModel> files;

  const ChecklistArchiveGroup({
    required this.checklistItemId,
    required this.checklistItemTitle,
    this.memo,
    this.images = const [],
    this.files = const [],
  });
}

List<ChecklistArchiveGroup> groupArchiveItemsByChecklistItem(
  List<AttachmentModel> items,
) {
  final Map<int, _MutableArchiveGroup> map = {};
  final List<int> order = [];

  for (final item in items) {
    final id = item.checklistItemId;
    if (id == null) continue;
    if (!map.containsKey(id)) {
      order.add(id);
      map[id] = _MutableArchiveGroup(
        checklistItemId: id,
        checklistItemTitle: item.checklistItemTitle ?? '체크리스트 항목',
      );
    }
    final g = map[id]!;
    if (item.attachmentType == 'MEMO') {
      g.memo = item;
    } else if (item.attachmentType == 'IMAGE') {
      g.images.add(item);
    } else if (item.attachmentType == 'FILE') {
      g.files.add(item);
    }
  }

  return order.map((id) => map[id]!.toGroup()).toList();
}

class _MutableArchiveGroup {
  final int checklistItemId;
  final String checklistItemTitle;
  AttachmentModel? memo;
  final List<AttachmentModel> images = [];
  final List<AttachmentModel> files = [];

  _MutableArchiveGroup({
    required this.checklistItemId,
    required this.checklistItemTitle,
  });

  ChecklistArchiveGroup toGroup() => ChecklistArchiveGroup(
    checklistItemId: checklistItemId,
    checklistItemTitle: checklistItemTitle,
    memo: memo,
    images: List.unmodifiable(images),
    files: List.unmodifiable(files),
  );
}
