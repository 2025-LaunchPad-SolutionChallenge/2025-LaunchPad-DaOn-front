import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/checklist/widget/itemBottomPopup.dart';
import 'package:project_daon/common/widget/tapBarWidget.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/core/service/selected_disaster_service.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final Dio _dio = AuthService().dio;

  DateTime _currentSelectedDate = DateTime.now();
  int _selectedIndex = 0;

  int? _userDisasterId;
  bool _isLoading = false;
  String? _errorMessage;
  double _completionRate = 0.0;
  List<_ChecklistItemView> _items = [];

  @override
  void initState() {
    super.initState();
    SelectedDisasterService.instance.selectedId.addListener(_onGlobalDisasterChanged);
    _loadChecklist();
  }

  @override
  void dispose() {
    SelectedDisasterService.instance.selectedId.removeListener(_onGlobalDisasterChanged);
    super.dispose();
  }

  void _onGlobalDisasterChanged() {
    if (!mounted) return;
    final id = SelectedDisasterService.instance.selectedId.value;
    if (id != null && id != _userDisasterId) {
      if (kDebugMode) debugPrint('[체크리스트] 전역 재난 변경 감지: userDisasterId=$id');
      _userDisasterId = id;
      _loadChecklist();
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  Future<int> _loadUserDisasterId() async {
    // 1순위: SelectedDisasterService (전역 선택 상태)
    final svcId = SelectedDisasterService.instance.selectedId.value;
    if (svcId != null) {
      _userDisasterId = svcId;
      if (kDebugMode) debugPrint('[체크리스트] 전역 선택 재난 사용: userDisasterId=$svcId');
      return svcId;
    }

    // 이미 조회된 값 재사용
    if (_userDisasterId != null) return _userDisasterId!;

    // 2순위: /home/summary에서 조회 (fallback)
    if (kDebugMode) debugPrint('[체크리스트] /home/summary에서 userDisasterId 조회');
    final response = await _dio.get('/api/v1/home/summary');
    final data = _asMap(response.data);
    final id = data['userDisasterId'];

    if (id is int) {
      _userDisasterId = id;
      await SelectedDisasterService.instance.select(id);
      return id;
    }

    if (id is num) {
      _userDisasterId = id.toInt();
      await SelectedDisasterService.instance.select(id.toInt());
      return id.toInt();
    }

    throw Exception('userDisasterId를 찾을 수 없습니다.');
  }

  Future<void> _loadChecklist() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final disasterId = await _loadUserDisasterId();
      final selectedDateText = _formatDate(_currentSelectedDate);

      debugPrint(
        '[체크리스트] 목록 조회: disasterId=$disasterId date=$selectedDateText',
      );

      final response = await _dio.get(
        '/api/v1/disasters/$disasterId/checklist',
        queryParameters: {'date': selectedDateText},
      );

      final data = _asMap(response.data);
      final days = _asList(data['days']);

      Map<String, dynamic>? selectedDay;
      for (final day in days) {
        final dayMap = _asMap(day);
        if (dayMap['checklistDate'] == selectedDateText) {
          selectedDay = dayMap;
          break;
        }
      }

      // 백엔드가 단일 날짜만 내려주는 경우를 대비한 fallback입니다.
      selectedDay ??= days.isNotEmpty ? _asMap(days.first) : null;

      final rawItems = _asList(selectedDay?['items']);
      debugPrint(
        '[체크리스트] 파싱 확인: days=${days.length}, selectedDate=$selectedDateText, rawItems=${rawItems.length}',
      );
      final parsedItems = rawItems
          .map((item) => _ChecklistItemView.fromJson(_asMap(item)))
          .where(
            (item) => item.checklistItemId != null && item.title.isNotEmpty,
          )
          .toList();

      final completionRate =
          (data['completionRate'] as num?)?.toDouble() ??
          _calculateCompletionRate(parsedItems);

      if (!mounted) return;
      setState(() {
        _items = parsedItems;
        _completionRate = completionRate;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '체크리스트를 불러오지 못했습니다.';
        _items = [];
        _completionRate = 0.0;
      });
      debugPrint('[체크리스트] 목록 조회 실패: $e');
    }
  }

  double _calculateCompletionRate(List<_ChecklistItemView> items) {
    if (items.isEmpty) return 0.0;
    final completed = items.where((item) => item.isCompleted).length;
    return (completed / items.length) * 100;
  }

  Future<void> _toggleChecklistItem(
    _ChecklistItemView item,
    bool newValue,
  ) async {
    final disasterId = _userDisasterId;
    final checklistItemId = item.checklistItemId;

    if (disasterId == null || checklistItemId == null) return;

    final previousItems = List<_ChecklistItemView>.from(_items);

    setState(() {
      _items = _items
          .map(
            (current) => current.checklistItemId == checklistItemId
                ? current.copyWith(isCompleted: newValue)
                : current,
          )
          .toList();
      _completionRate = _calculateCompletionRate(_items);
    });

    try {
      await _dio.patch(
        '/api/v1/disasters/$disasterId/checklist/$checklistItemId/status',
        data: {'isCompleted': newValue},
      );
      await _loadChecklist();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = previousItems;
        _completionRate = _calculateCompletionRate(_items);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('완료 상태 변경에 실패했습니다.')));
      debugPrint('[체크리스트] 완료 상태 변경 실패: $e');
    }
  }

  void _showBottomSheet() {
    final dummy = ChecklistItemModel(checklistItemId: 0, isAiGenerated: false, title: '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => ItemBottomPopupWidget(
        item: dummy,
        onEdit: () => Navigator.pop(ctx),
        onDelete: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showBottomSheet22() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => AddBottomPopupWidget(
        onSubmit: (_) => Navigator.pop(ctx),
      ),
    );
  }

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
      await _loadChecklist();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _loadChecklist();
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) _loadChecklist();
      });
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
        onEdit: () => Navigator.pop(ctx),
        onDelete: () {
          Navigator.pop(ctx);
          _deleteItemById(selectedItem.checklistItemId);
        },
      ),
    );
  }

  Future<void> _deleteItemById(int checklistItemId) async {
    final disasterId = _userDisasterId;
    if (disasterId == null) return;
    try {
      await _dio.delete(
        '/api/v1/disasters/$disasterId/checklist/$checklistItemId',
      );
      _loadChecklist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('항목 삭제에 실패했습니다.')),
        );
      }
    }
  }

  Widget _buildChecklistTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorStyles.main2),
      );
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

    return RefreshIndicator(
      onRefresh: _loadChecklist,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120.0),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) {
          final item = _items[index];
          final widgetItem = item.toWidgetModel();

          return ChecklistItemWidget(
            item: widgetItem,
            onCheckChanged: (bool newValue) {
              _toggleChecklistItem(item, newValue);
            },
            onOptionsTap: _showItemOptionsBottomSheet,
          );
        },
      ),
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
              child: AiChecklistFloatingButton(onPressed: _navigateToNewPage),
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
                child: Text(
                  '${_currentSelectedDate.month}.${_currentSelectedDate.day}',
                  style: FontStyles.med20,
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildChecklistTab(),
                    Column(
                      children: [
                        const SizedBox(height: 60.0),
                        const Text('아카이빙 페이지'),
                        ElevatedButton(
                          onPressed: _showBottomSheet,
                          child: const Text('버튼'),
                        ),
                        ElevatedButton(
                          onPressed: _showBottomSheet22,
                          child: const Text('버튼'),
                        ),
                      ],
                    ),
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

class _ChecklistItemView {
  final int? checklistItemId;
  final String title;
  final bool isCompleted;
  final bool isAiGenerated;
  final String memo;
  final List<String> imageUrls;

  const _ChecklistItemView({
    required this.checklistItemId,
    required this.title,
    required this.isCompleted,
    required this.isAiGenerated,
    this.memo = '',
    this.imageUrls = const [],
  });

  factory _ChecklistItemView.fromJson(Map<String, dynamic> json) {
    final rawId = json['checklistItemId'] ?? json['id'];
    final imageUrls =
        json['imageUrls'] ?? json['images'] ?? json['attachments'];

    return _ChecklistItemView(
      checklistItemId: rawId is int
          ? rawId
          : rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      isAiGenerated: json['isAiGenerated'] == true,
      memo: json['memo']?.toString() ?? '',
      imageUrls: imageUrls is List
          ? imageUrls.map((e) => e.toString()).toList()
          : const [],
    );
  }

  _ChecklistItemView copyWith({bool? isCompleted}) {
    return _ChecklistItemView(
      checklistItemId: checklistItemId,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      isAiGenerated: isAiGenerated,
      memo: memo,
      imageUrls: imageUrls,
    );
  }

  ChecklistItemModel toWidgetModel() {
    return ChecklistItemModel(
      checklistItemId: checklistItemId ?? 0,
      title: title,
      isChecked: isCompleted,
      isAiGenerated: isAiGenerated,
      memo: memo,
      imageUrls: imageUrls,
    );
  }
}
