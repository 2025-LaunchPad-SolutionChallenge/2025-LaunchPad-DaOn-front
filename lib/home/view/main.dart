import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/common/widget/yellowBackButton.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/home/view/dailyStatusCheckPage.dart';
import 'package:project_daon/home/widget/semiCircleProgressBar.dart';
import 'package:project_daon/home/widget/homeAppBar.dart';
import 'package:project_daon/home/widget/startBlock.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Sheet state ──
  double _sheetPosition = 0.27;
  final double _minSheetSize = 0.27;
  final double _maxSheetSize = 0.77;
  final double _expandThreshold = 0.5;
  bool _isExpanded = false;

  // ── API data ──
  HomeSummary? _summary;
  bool _todayCheckDone = false;
  RecoveryStageResponse? _stage;
  List<UserDisasterSummary> _disasters = [];
  int? _selectedDisasterId;
  double? _selectedProgress; // null = use _summary.recoveryProgress

  // ── Task state ──
  List<TodayTaskItem> _shortTasks = [];
  List<TodayTaskItem> _fullTasks = [];
  bool _fullTasksFetched = false; // true = _fullTasks에 유효한 데이터가 있음
  bool _fullTasksFetching = false; // true = 전체 할 일 요청 중
  bool _tasksInitiallyLoaded = false;

  final HomeApi _homeApi = HomeApi();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Helpers ──

  Future<T?> _safeGet<T>(Future<T> future, String label) async {
    try {
      return await future;
    } catch (e) {
      if (kDebugMode) debugPrint('$label: $e');
      return null;
    }
  }

  // ── Data loading ──

  Future<void> _loadAll() async {
    final summaryFuture = _safeGet<HomeSummary>(
      _homeApi.getHomeSummary(),
      '[홈] 요약 조회 실패',
    );
    final dailyStatusFuture = _safeGet<DailyStatusCheckStatus>(
      _homeApi.getDailyStatus(),
      '[홈] 상태 체크 조회 실패',
    );
    final tasksFuture = _safeGet<TodayTasksResponse>(
      _homeApi.getTodayTasks(),
      '[홈] 할 일 조회 실패',
    );
    final disastersFuture = _safeGet<DisasterListResponse>(
      _homeApi.getDisasterList(),
      '[홈] 재난 목록 조회 실패',
    );

    final summary = await summaryFuture;
    final dailyStatus = await dailyStatusFuture;
    final tasks = await tasksFuture;
    final disasters = await disastersFuture;

    if (!mounted) return;

    setState(() {
      if (summary != null) _summary = summary;
      if (dailyStatus != null) _todayCheckDone = dailyStatus.checked;
      if (tasks != null) _shortTasks = tasks.items;
      if (disasters != null) _disasters = disasters.content;
      _selectedDisasterId = summary?.userDisasterId;
      _tasksInitiallyLoaded = true;
    });

    if (summary != null) {
      _loadStage(summary.userDisasterId);
    }
  }

  Future<void> _loadStage(int disasterId) async {
    final stage = await _safeGet<RecoveryStageResponse>(
      _homeApi.getRecoveryStage(disasterId),
      '[홈] 회복 단계 조회 실패',
    );
    if (!mounted || stage == null) return;
    setState(() => _stage = stage);
  }

  Future<void> _loadFullTasks() async {
    if (_fullTasksFetching || _fullTasksFetched) return;
    _fullTasksFetching = true;
    try {
      final response = await _homeApi.getTodayTasksFull();
      if (!mounted) return;
      setState(() {
        _fullTasks = response.items;
        _fullTasksFetched = true;
        _fullTasksFetching = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[홈] 전체 할 일 조회 실패: $e');
      _fullTasksFetching = false;
    }
  }

  Future<void> _refetchAfterCheck() async {
    final dailyStatusFuture = _safeGet<DailyStatusCheckStatus>(
      _homeApi.getDailyStatus(),
      '[홈] 상태 체크 재조회 실패',
    );
    final summaryFuture = _safeGet<HomeSummary>(
      _homeApi.getHomeSummary(),
      '[홈] 요약 재조회 실패',
    );
    final tasksFuture = _safeGet<TodayTasksResponse>(
      _homeApi.getTodayTasks(),
      '[홈] 할 일 재조회 실패',
    );

    final dailyStatus = await dailyStatusFuture;
    final summary = await summaryFuture;
    final tasks = await tasksFuture;

    if (!mounted) return;
    setState(() {
      if (dailyStatus != null) _todayCheckDone = dailyStatus.checked;
      if (summary != null) _summary = summary;
      if (tasks != null) _shortTasks = tasks.items;
      _fullTasksFetched = false;
      _fullTasksFetching = false;
      _fullTasks = [];
    });
  }

  Future<void> _refetchSummary() async {
    final summary = await _safeGet<HomeSummary>(
      _homeApi.getHomeSummary(),
      '[홈] 요약 재조회 실패',
    );
    if (!mounted || summary == null) return;
    setState(() => _summary = summary);
  }

  // ── Navigation ──

  Future<void> _navigateToCheck() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyStatusCheckPage()),
    );
    if (done == true) {
      _refetchAfterCheck();
    }
  }

  // ── Task toggle ──

  Future<void> _toggleTask(TodayTaskItem item) async {
    final disasterId = _selectedDisasterId;
    if (disasterId == null) return;

    final newValue = !item.isCompleted;

    void updateInList(List<TodayTaskItem> list) {
      final idx = list.indexWhere(
        (t) => t.checklistItemId == item.checklistItemId,
      );
      if (idx != -1) list[idx].isCompleted = newValue;
    }

    setState(() {
      updateInList(_shortTasks);
      updateInList(_fullTasks);
    });

    try {
      await _homeApi.updateChecklistStatus(
        userDisasterId: disasterId,
        checklistItemId: item.checklistItemId,
        isCompleted: newValue,
      );
      _refetchSummary();
    } catch (e) {
      if (!mounted) return;
      void rollback(List<TodayTaskItem> list) {
        final idx = list.indexWhere(
          (t) => t.checklistItemId == item.checklistItemId,
        );
        if (idx != -1) list[idx].isCompleted = !newValue;
      }

      setState(() {
        rollback(_shortTasks);
        rollback(_fullTasks);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('완료 상태 변경에 실패했습니다.')));
    }
  }

  // ── UI helpers ──

  String _charImagePath() {
    final stageId = _stage?.stageId;
    if (stageId != null && stageId >= 1 && stageId <= 5) {
      return 'assets/home/daon$stageId.png';
    }
    return 'assets/home/exChar.png';
  }

  Widget _buildTaskItem(TodayTaskItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => _toggleTask(item),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? ColorStyles.main1
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted
                      ? ColorStyles.main1
                      : ColorStyles.grey2,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                item.title,
                style: FontStyles.med14.copyWith(
                  color: item.isCompleted
                      ? ColorStyles.grey1
                      : ColorStyles.black2,
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: ColorStyles.grey1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _initialDropdownIndex {
    if (_disasters.isEmpty || _selectedDisasterId == null) return 0;
    final idx = _disasters.indexWhere(
      (d) => d.userDisasterId == _selectedDisasterId,
    );
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final double dimOpacity =
        ((_sheetPosition - _minSheetSize) / (_maxSheetSize - _minSheetSize))
            .clamp(0.0, 1.0) *
        0.6;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomSheetHeight = screenHeight * _minSheetSize;

    final double progress =
        (_selectedProgress ?? _summary?.recoveryProgress ?? 0) / 100;

    final displayTasks = _isExpanded && _fullTasksFetched
        ? _fullTasks
        : _shortTasks;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HomeAppBarWidget(),
      body: Stack(
        children: [
          // ── 배경 + 상단 콘텐츠 ──
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorStyles.main2, ColorStyles.main3],
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomSheetHeight),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Dropdown(
                      items: _disasters.isNotEmpty
                          ? _disasters.map((d) => d.displayLabel).toList()
                          : null,
                      initialIndex: _initialDropdownIndex,
                      onIndexChanged: (index) {
                        if (index < 0 || index >= _disasters.length) return;
                        final disaster = _disasters[index];
                        setState(() {
                          _selectedDisasterId = disaster.userDisasterId;
                          _selectedProgress = disaster.recoveryProgress;
                          _stage = null;
                        });
                        _loadStage(disaster.userDisasterId);
                      },
                    ),
                    const SizedBox(height: 12.0),
                    StartBlock(
                      name: _summary?.userName,
                      myStep: _stage?.stageName,
                      description: _stage?.description,
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              _charImagePath(),
                              errorBuilder: (_, __, ___) =>
                                  Image.asset('assets/home/exChar.png'),
                              width: 240,
                            ),
                            const SizedBox(height: 16.0),
                            SemiCircleProgressBar(
                              percentage: progress.clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 20.0),
                            AbsorbPointer(
                              absorbing: _todayCheckDone,
                              child: Opacity(
                                opacity: _todayCheckDone ? 0.55 : 1.0,
                                child: YellowBackButton(
                                  text: _todayCheckDone
                                      ? "오늘의 상태 체크 완료"
                                      : "오늘의 상태 체크",
                                  onPressed: _navigateToCheck,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 디밍 레이어 ──
          IgnorePointer(
            child: Container(color: Colors.black.withOpacity(dimOpacity)),
          ),

          // ── 드래그 가능한 하단 체크리스트 박스 ──
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final extent = notification.extent;
              final nowExpanded = extent > _expandThreshold;
              final triggerLoad =
                  nowExpanded &&
                  !_isExpanded &&
                  !_fullTasksFetched &&
                  !_fullTasksFetching;

              setState(() {
                _sheetPosition = extent;
                _isExpanded = nowExpanded;
              });

              if (triggerLoad) _loadFullTasks();
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: _minSheetSize,
              minChildSize: _minSheetSize,
              maxChildSize: _maxSheetSize,
              snap: true,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const ShapeDecoration(
                    color: ColorStyles.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(17),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 핸들바
                          Center(
                            child: Container(
                              width: 75,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '오늘의 할 일',
                                style: FontStyles.semi16.copyWith(
                                  color: ColorStyles.black2,
                                ),
                              ),
                              if (_summary != null)
                                Text(
                                  '${_summary!.todayCompletedTasks}/${_summary!.todayTotalTasks}',
                                  style: FontStyles.med14.copyWith(
                                    color: ColorStyles.grey1,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 할 일 목록
                          if (!_tasksInitiallyLoaded ||
                              (displayTasks.isEmpty && _fullTasksFetching))
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: CircularProgressIndicator(
                                  color: ColorStyles.main1,
                                  strokeWidth: 2.0,
                                ),
                              ),
                            )
                          else if (displayTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                '아직 오늘의 할 일이 생성되지 않았습니다.',
                                style: FontStyles.med14.copyWith(
                                  color: ColorStyles.grey1,
                                ),
                              ),
                            )
                          else ...[
                            ...displayTasks.map(_buildTaskItem),
                            // 확장 상태에서 전체 할 일 로딩 중이면 목록 아래 인디케이터
                            if (_isExpanded && _fullTasksFetching)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: CircularProgressIndicator(
                                    color: ColorStyles.main1,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
