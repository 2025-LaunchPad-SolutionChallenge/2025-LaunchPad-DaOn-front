import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/checklist/api/checklist_api.dart';
import 'package:project_daon/checklist/model/attachment_model.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/attachBottomPopup.dart';
import 'package:project_daon/checklist/widget/attachmentItemBottomPopup.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/checklist/widget/itemBottomPopup.dart';
import 'package:project_daon/checklist/widget/memoBottomPopup.dart';
import 'package:project_daon/checklist/widget/pictureButton.dart';
import 'package:project_daon/common/widget/tapBarWidget.dart';
import 'package:project_daon/core/service/selected_disaster_service.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final _homeApi = HomeApi();
  final _checklistApi = ChecklistApi();

  DateTime _currentSelectedDate = DateTime.now();
  int _selectedIndex = 0;

  List<ChecklistItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _completionRate = 0.0;
  int? _userDisasterId;

  List<AttachmentModel> _archiveItems = [];
  bool _isArchiveLoading = false;

  final Set<int> _pendingStatusIds = {};

  static String _fmtDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    SelectedDisasterService.instance.selectedId
        .addListener(_onGlobalDisasterChanged);
    final svcId = SelectedDisasterService.instance.selectedId.value;
    if (svcId != null) _userDisasterId = svcId;
    _loadChecklist().whenComplete(() {
      if (mounted) _loadArchive();
    });
  }

  @override
  void dispose() {
    SelectedDisasterService.instance.selectedId
        .removeListener(_onGlobalDisasterChanged);
    super.dispose();
  }

  void _onGlobalDisasterChanged() {
    if (!mounted) return;
    final id = SelectedDisasterService.instance.selectedId.value;
    if (id != null && id != _userDisasterId) {
      if (kDebugMode) debugPrint('[체크리스트] 전역 재난 변경: userDisasterId=$id');
      _userDisasterId = id;
      _loadChecklist();
      _loadArchive();
    }
  }

  Future<void> _loadChecklist() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      if (_userDisasterId == null) {
        final svcId = SelectedDisasterService.instance.selectedId.value;
        if (svcId != null) {
          _userDisasterId = svcId;
        } else {
          final summary = await _homeApi.getHomeSummary();
          _userDisasterId = summary.userDisasterId;
          await SelectedDisasterService.instance.select(_userDisasterId!);
        }
      }
      final result = await _checklistApi.fetchChecklist(
        _userDisasterId!,
        _currentSelectedDate,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _completionRate = result.completionRate;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '체크리스트를 불러오는 데 실패했습니다.';
        });
      }
    }
  }

  Future<void> _loadArchive() async {
    if (_userDisasterId == null || !mounted) return;
    setState(() => _isArchiveLoading = true);
    try {
      final items = await _checklistApi.fetchArchive(
        _userDisasterId!,
        type: 'ALL',
        date: _fmtDate(_currentSelectedDate),
      );
      if (mounted) {
        setState(() {
          _archiveItems = items;
          _isArchiveLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[아카이브] 로드 실패: $e');
      if (mounted) setState(() => _isArchiveLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadChecklist(), _loadArchive()]);
  }

  // ── 체크리스트 CRUD ───────────────────────────────────────────

  void _showAddPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AddBottomPopupWidget(
        onSubmit: (title) {
          Navigator.pop(ctx);
          _addItem(title);
        },
      ),
    );
  }

  Future<void> _addItem(String title) async {
    if (_userDisasterId == null) return;
    try {
      await _checklistApi.addChecklistItem(
        userDisasterId: _userDisasterId!,
        title: title,
        checklistDate: _fmtDate(_currentSelectedDate),
      );
      _loadChecklist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('항목 추가에 실패했습니다.')),
        );
      }
    }
  }

  void _showEditPopup(ChecklistItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AddBottomPopupWidget(
        initialTitle: item.title,
        onSubmit: (title) {
          Navigator.pop(ctx);
          _editItem(item, title);
        },
      ),
    );
  }

  Future<void> _editItem(ChecklistItemModel item, String title) async {
    if (_userDisasterId == null) return;
    final dateStr = item.checklistDate ?? _fmtDate(_currentSelectedDate);
    try {
      await _checklistApi.editChecklistItem(
        userDisasterId: _userDisasterId!,
        checklistItemId: item.checklistItemId,
        title: title,
        checklistDate: dateStr,
        isCompleted: item.isChecked,
        priority: item.priority,
      );
      _loadChecklist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('항목 수정에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _deleteItem(ChecklistItemModel item) async {
    if (_userDisasterId == null) return;
    try {
      await _checklistApi.deleteChecklistItem(
        userDisasterId: _userDisasterId!,
        checklistItemId: item.checklistItemId,
      );
      _loadChecklist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('항목 삭제에 실패했습니다.')),
        );
      }
    }
  }

  void _showItemOptionsBottomSheet(ChecklistItemModel selectedItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => ItemBottomPopupWidget(
        item: selectedItem,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditPopup(selectedItem);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteItem(selectedItem);
        },
        onMemo: () {
          Navigator.pop(ctx);
          _showMemoAddPopup(selectedItem);
        },
      ),
    );
  }

  Future<void> _onCheckChanged(int index, bool newValue) async {
    final item = _items[index];
    final itemId = item.checklistItemId;
    if (_pendingStatusIds.contains(itemId)) return;
    if (_userDisasterId == null) return;

    setState(() {
      _pendingStatusIds.add(itemId);
      _items[index].isChecked = newValue;
    });
    try {
      await _checklistApi.updateChecklistStatus(
        userDisasterId: _userDisasterId!,
        checklistItemId: itemId,
        isCompleted: newValue,
      );
      if (mounted) await _loadChecklist();
    } catch (_) {
      if (mounted) {
        setState(() => _items[index].isChecked = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 변경에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingStatusIds.remove(itemId));
    }
  }

  // ── 메모 첨부 ─────────────────────────────────────────────────

  void _showMemoAddPopup(ChecklistItemModel selectedItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => MemoAttachBottomPopupWidget(
        items: _items,
        initialChecklistItemId: selectedItem.checklistItemId,
        onSubmit: (checklistItemId, content) {
          Navigator.pop(ctx);
          _addMemoAttachment(checklistItemId, content);
        },
      ),
    );
  }

  Future<void> _addMemoAttachment(int checklistItemId, String content) async {
    if (_userDisasterId == null) return;
    try {
      await _checklistApi.addAttachment(_userDisasterId!, checklistItemId, {
        'attachmentType': 'MEMO',
        'content': content,
        'fileUrl': null,
        'originalFileName': null,
        'mimeType': null,
        'fileSize': null,
        'thumbnailUrl': null,
      });
      await _refreshAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메모 추가에 실패했습니다.')),
        );
      }
    }
  }

  // ── 파일/이미지 첨부 ───────────────────────────────────────────

  void _showAttachBottomPopup() {
    if (_userDisasterId == null || _items.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AttachBottomPopupWidget(
        items: _items,
        userDisasterId: _userDisasterId!,
        onSuccess: _refreshAll,
      ),
    );
  }

  // ── 첨부 편집/삭제 ─────────────────────────────────────────────

  void _showAttachmentOptions(AttachmentModel attachment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AttachmentItemBottomPopupWidget(
        attachment: attachment,
        onEdit: () {
          Navigator.pop(ctx);
          if (attachment.attachmentType == 'MEMO') {
            _showMemoEditPopup(attachment);
          } else {
            _showFileNameEditPopup(attachment);
          }
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteAttachment(attachment);
        },
      ),
    );
  }

  void _showMemoEditPopup(AttachmentModel attachment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => MemoAttachBottomPopupWidget(
        isEditMode: true,
        initialChecklistItemId: attachment.checklistItemId,
        initialTitle: parseMemoTitle(attachment.content),
        initialBody: parseMemoBody(attachment.content),
        onSubmit: (_, content) {
          Navigator.pop(ctx);
          _editMemoAttachment(attachment, content);
        },
      ),
    );
  }

  Future<void> _editMemoAttachment(
    AttachmentModel attachment,
    String content,
  ) async {
    if (_userDisasterId == null || attachment.checklistItemId == null) return;
    try {
      await _checklistApi.editAttachment(
        _userDisasterId!,
        attachment.checklistItemId!,
        attachment.attachmentId,
        {
          'content': content,
          'fileUrl': null,
          'originalFileName': null,
          'mimeType': null,
          'fileSize': null,
          'thumbnailUrl': null,
        },
      );
      await _refreshAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메모 수정에 실패했습니다.')),
        );
      }
    }
  }

  void _showFileNameEditPopup(AttachmentModel attachment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AddBottomPopupWidget(
        initialTitle: attachment.originalFileName,
        onSubmit: (title) {
          Navigator.pop(ctx);
          _editFileAttachment(attachment, title);
        },
      ),
    );
  }

  Future<void> _editFileAttachment(
    AttachmentModel attachment,
    String newFileName,
  ) async {
    if (_userDisasterId == null || attachment.checklistItemId == null) return;
    try {
      await _checklistApi.editAttachment(
        _userDisasterId!,
        attachment.checklistItemId!,
        attachment.attachmentId,
        {
          'content': null,
          'fileUrl': attachment.fileUrl,
          'originalFileName': newFileName,
          'mimeType': attachment.mimeType,
          'fileSize': attachment.fileSize,
          'thumbnailUrl': attachment.thumbnailUrl,
        },
      );
      await _refreshAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 이름 수정에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _deleteAttachment(AttachmentModel attachment) async {
    if (_userDisasterId == null || attachment.checklistItemId == null) return;
    try {
      await _checklistApi.deleteAttachment(
        _userDisasterId!,
        attachment.checklistItemId!,
        attachment.attachmentId,
      );
      await _refreshAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('첨부 삭제에 실패했습니다.')),
        );
      }
    }
  }

  // ── AI 체크리스트 페이지 이동 ───────────────────────────────────

  Future<void> _navigateToNewPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistAiAddPage(
          selectedDate: _currentSelectedDate,
          initialUserDisasterId: _userDisasterId,
        ),
      ),
    );
    if (result == true) {
      _loadChecklist();
    }
  }

  // ── UI 빌더 ────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: ColorStyles.main2,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            title,
            style: FontStyles.med16.copyWith(color: ColorStyles.black1),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentGrid(List<AttachmentModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final attachment = items[index];
        final url = attachment.thumbnailUrl ?? attachment.fileUrl;
        return GestureDetector(
          onLongPress: () => _showAttachmentOptions(attachment),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fileNameTile(attachment),
                  )
                : _fileNameTile(attachment),
          ),
        );
      },
    );
  }

  Widget _fileNameTile(AttachmentModel attachment) {
    return Container(
      color: ColorStyles.secon5,
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          attachment.originalFileName ?? '파일',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
          textAlign: TextAlign.center,
          style: FontStyles.med12.copyWith(color: ColorStyles.black2),
        ),
      ),
    );
  }

  Widget _buildArchiveTab() {
    if (_isArchiveLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorStyles.main2),
      );
    }

    final memoItems =
        _archiveItems.where((a) => a.attachmentType == 'MEMO').toList();
    final fileItems =
        _archiveItems.where((a) => a.attachmentType != 'MEMO').toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memoItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: ColorStyles.secon5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Memo', style: FontStyles.semi16),
                  const SizedBox(height: 12.0),
                  Text(
                    '메모가 없습니다.',
                    style: FontStyles.med14.copyWith(color: ColorStyles.black2),
                  ),
                ],
              ),
            )
          else
            ...memoItems.map(
              (memo) => GestureDetector(
                onLongPress: () => _showAttachmentOptions(memo),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: ColorStyles.secon5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parseMemoTitle(memo.content),
                        style: FontStyles.semi16,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        parseMemoBody(memo.content),
                        style: FontStyles.med14.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (fileItems.isNotEmpty) ...[
            const SizedBox(height: 28.0),
            _buildSectionTitle('All'),
            const SizedBox(height: 12.0),
            _buildAttachmentGrid(fileItems),
          ],
          const SizedBox(height: 120.0),
        ],
      ),
    );
  }

  Widget _buildChecklistTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: FontStyles.med14.copyWith(color: ColorStyles.black2),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: CheckNullWidget());
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ChecklistItemWidget(
          item: _items[index],
          onCheckChanged: (bool newValue) {
            _onCheckChanged(index, newValue);
          },
          onOptionsTap: _showItemOptionsBottomSheet,
          onFetchAttachments: _userDisasterId == null
              ? null
              : () => _checklistApi.fetchChecklistDetail(
                    _userDisasterId!,
                    _items[index].checklistItemId,
                  ),
          onAttachmentLongPress: _showAttachmentOptions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: AiChecklistFloatingButton(
                onPressed: () {
                  _navigateToNewPage();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChecklistProgessBar(currentCheck: _completionRate),
              ChecklistWeekWidget(
                selectedDate: _currentSelectedDate,
                onDateSelected: (newDate) {
                  setState(() => _currentSelectedDate = newDate);
                  _loadChecklist();
                  _loadArchive();
                },
              ),
              const SizedBox(height: 20.0),
              TabBarWidget(
                selectedIndex: _selectedIndex,
                onTabChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 33.0,
                      child: Text(
                        '${_currentSelectedDate.month}.${_currentSelectedDate.day}',
                        style: FontStyles.med20,
                      ),
                    ),
                    if (_selectedIndex == 1)
                      PictureButton(
                        text: '등록하기',
                        onPressed: _showAttachBottomPopup,
                        width: 100.0,
                        height: 33.0,
                      ),
                    if (_selectedIndex == 0)
                      PictureButton(
                        text: '생성하기',
                        onPressed:
                            _userDisasterId != null ? _showAddPopup : null,
                        width: 100.0,
                        height: 33.0,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildChecklistTab(),
                    _buildArchiveTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
