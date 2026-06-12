import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/common/widget/skeletonBox.dart';
import 'package:project_daon/common/widget/yellowBackButton.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/core/service/selected_disaster_service.dart';
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
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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
  RecoveryProgress? _recoveryProgress;
  List<UserDisasterSummary> _disasters = [];
  int? _selectedDisasterId;
  double? _selectedProgress; // null = use _recoveryProgress.recoveryScore

  // ── Task state ──
  List<TodayTaskItem> _shortTasks = [];
  List<TodayTaskItem> _fullTasks = [];
  bool _fullTasksFetched = false; // true = _fullTasks에 유효한 데이터가 있음
  bool _fullTasksFetching = false; // true = 전체 할 일 요청 중
  bool _tasksInitiallyLoaded = false;
  bool _isDisasterSwitching = false;

  final HomeApi _homeApi = HomeApi();

  @override
  void initState() {
    super.initState();
    SelectedDisasterService.instance.selectedId.addListener(
      _onGlobalDisasterChanged,
    );
    _loadAll();
  }

  @override
  void dispose() {
    SelectedDisasterService.instance.selectedId.removeListener(
      _onGlobalDisasterChanged,
    );
    super.dispose();
  }

  void _onGlobalDisasterChanged() {
    if (!mounted) return;
    final id = SelectedDisasterService.instance.selectedId.value;
    if (id != null && id != _selectedDisasterId) {
      if (kDebugMode) debugPrint('[홈] 전역 재난 변경 감지: userDisasterId=$id');
      final match = _disasters.where((d) => d.userDisasterId == id);
      setState(() {
        _selectedDisasterId = id;
        _selectedProgress = match.isNotEmpty
            ? match.first.recoveryProgress
            : null;
        _stage = null;
        _recoveryProgress = null;
        _isDisasterSwitching = true;
      });
      _loadStage(id);
      // TODO: /api/v1/home/summary 및 /api/v1/home/today-tasks가 userDisasterId 쿼리 파라미터를
      // 지원하지 않으므로, 재난 변경 시 요약/할 일을 다른 재난 기준으로 재조회할 수 없습니다.
      // 백엔드에서 해당 파라미터를 지원하면 여기서 _refetchAfterCheck()를 호출하세요.
    }
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

    // 저장된 선택 ID 복원 (없으면 storage에서)
    if (SelectedDisasterService.instance.selectedId.value == null) {
      await SelectedDisasterService.instance.initFromStorage();
    }

    // 선택 ID 결정: 저장값 → 목록에 있으면 유지, 없으면 summary ID로 fallback
    final svc = SelectedDisasterService.instance;
    final disasterList = disasters?.content ?? [];
    final savedId = svc.selectedId.value;
    int? activeId;

    if (savedId != null &&
        disasterList.any((d) => d.userDisasterId == savedId)) {
      activeId = savedId;
    } else {
      activeId = summary?.userDisasterId;
      if (activeId != null) await svc.select(activeId);
    }

    setState(() {
      if (summary != null) _summary = summary;
      if (dailyStatus != null) _todayCheckDone = dailyStatus.checked;
      if (tasks != null) _shortTasks = tasks.items;
      if (disasters != null) _disasters = disasters.content;
      _selectedDisasterId = activeId ?? summary?.userDisasterId;
      _tasksInitiallyLoaded = true;
    });

    final loadId = activeId ?? summary?.userDisasterId;
    if (loadId != null) {
      _loadStage(loadId);
    }
  }

  Future<void> _loadStage(int disasterId) async {
    final stageFuture = _safeGet<RecoveryStageResponse>(
      _homeApi.getRecoveryStage(disasterId),
      '[홈] 회복 단계 조회 실패',
    );
    final progressFuture = _safeGet<RecoveryProgress>(
      _homeApi.fetchRecoveryProgress(disasterId),
      '[홈] 회복 진행도 조회 실패',
    );
    final stage = await stageFuture;
    final progress = await progressFuture;
    if (!mounted) return;
    setState(() {
      if (stage != null) _stage = stage;
      if (progress != null) _recoveryProgress = progress;
      _isDisasterSwitching = false;
    });
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
      await _homeApi.runRecoveryBatch();
      _refetchSummary();
      _loadStage(disasterId);
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

  Widget _buildStartBlockSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 190, height: 22, isLight: true),
        const SizedBox(height: 8),
        SkeletonBox(width: 230, height: 22, isLight: true),
        const SizedBox(height: 20),
        Row(
          children: [
            SkeletonBox(
              width: 100,
              height: 42,
              borderRadius: BorderRadius.circular(7),
              isLight: true,
            ),
            const SizedBox(width: 8),
            SkeletonBox(width: 80, height: 22, isLight: true),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterAreaSkeleton() {
    return SkeletonBox(
      width: 260,
      height: 300,
      borderRadius: BorderRadius.circular(24),
      isLight: true,
    );
  }

  Widget _buildTaskListSkeleton() {
    const widths = [180.0, 220.0, 150.0, 200.0];
    return Column(
      children: List.generate(widths.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Row(
          children: [
            SkeletonBox(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(width: 8),
            SkeletonBox(width: widths[i], height: 14),
          ],
        ),
      )),
    );
  }

  Widget _buildTaskItem(TodayTaskItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: GestureDetector(
        onTap: () => _toggleTask(item),
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? ColorStyles.main2
                      : ColorStyles.secon5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(width: 8),

            if (item.isAiGenerated) ...[
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 5),
            ],

            Expanded(
              child: _WordWrapText(
                text: item.title,
                style: FontStyles.med14.copyWith(
                  color: item.isCompleted
                      ? ColorStyles.black2.withValues(alpha: 0.45)
                      : ColorStyles.black2,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refreshTodayTasksFromOutside() async {
    final tasksFuture = _safeGet<TodayTasksResponse>(
      _homeApi.getTodayTasks(),
      '[홈] 탭 복귀 할 일 재조회 실패',
    );
    final summaryFuture = _safeGet<HomeSummary>(
      _homeApi.getHomeSummary(),
      '[홈] 탭 복귀 요약 재조회 실패',
    );
    final disastersFuture = _safeGet<DisasterListResponse>(
      _homeApi.getDisasterList(),
      '[홈] 탭 복귀 재난 목록 재조회 실패',
    );

    final tasks = await tasksFuture;
    final summary = await summaryFuture;
    final disasters = await disastersFuture;

    if (!mounted) return;
    setState(() {
      if (tasks != null) _shortTasks = tasks.items;
      if (summary != null) _summary = summary;
      if (disasters != null) {
        _disasters = disasters.content;
        // 선택된 재난의 recoveryProgress도 최신값으로 갱신
        if (_selectedDisasterId != null) {
          final match = disasters.content.where(
            (d) => d.userDisasterId == _selectedDisasterId,
          );
          if (match.isNotEmpty) {
            _selectedProgress = match.first.recoveryProgress;
          }
        }
      }
    });

    final disasterId = _selectedDisasterId ?? summary?.userDisasterId;
    if (disasterId != null) {
      _loadStage(disasterId);
    }

    if (_fullTasksFetched) {
      final full = await _safeGet<TodayTasksResponse>(
        _homeApi.getTodayTasksFull(),
        '[홈] 탭 복귀 전체 할 일 재조회 실패',
      );
      if (!mounted || full == null) return;
      setState(() => _fullTasks = full.items);
    }
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
    final bool isSkeletonVisible = !_tasksInitiallyLoaded || _isDisasterSwitching;

    final double dimOpacity =
        ((_sheetPosition - _minSheetSize) / (_maxSheetSize - _minSheetSize))
            .clamp(0.0, 1.0) *
        0.6;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomSheetHeight = screenHeight * _minSheetSize;

    // 모든 진행률 값은 0~100 스케일. SemiCircleProgressBar는 0~1 기대하므로 /100.
    final double progress =
        (_recoveryProgress?.recoveryScore ??
                _selectedProgress ??
                _summary?.recoveryProgress ??
                0)
            .clamp(0.0, 100.0) /
        100.0;

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

                colors: [
                  ColorStyles.main2, // 상단의 민트/그린
                  ColorStyles.main3, // 하단의 연노랑
                ],

                stops: [0.01, 0.8],
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
                        if (kDebugMode)
                          debugPrint(
                            '[홈] 드롭다운 선택: userDisasterId=${disaster.userDisasterId}',
                          );
                        SelectedDisasterService.instance.select(
                          disaster.userDisasterId,
                        );
                        setState(() {
                          _selectedDisasterId = disaster.userDisasterId;
                          _selectedProgress = disaster.recoveryProgress;
                          _stage = null;
                          _recoveryProgress = null;
                          _isDisasterSwitching = true;
                        });
                        _loadStage(disaster.userDisasterId);
                      },
                    ),
                    const SizedBox(height: 12.0),
                    isSkeletonVisible
                        ? _buildStartBlockSkeleton()
                        : StartBlock(
                            name: _summary?.userName,
                            myStep: _stage?.stageName,
                            description: _stage?.description,
                          ),
                    Expanded(
                      child: Center(
                        child: isSkeletonVisible
                            ? _buildCenterAreaSkeleton()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    _charImagePath(),
                                    errorBuilder: (_, __, ___) =>
                                        Image.asset('assets/home/exChar.png'),
                                    width: 240,
                                  ),
                                  const SizedBox(height: 18.0),
                                  SemiCircleProgressBar(
                                    percentage: progress.clamp(0.0, 1.0),
                                  ),
                                  const SizedBox(height: 25.0),
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
                                color: ColorStyles.grey2,
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
                                  fontSize: 18.0,
                                ),
                              ),
                              if (!_tasksInitiallyLoaded)
                                SkeletonBox(width: 40, height: 14, isLight: false)
                              else if (_summary != null)
                                Text(
                                  '${_summary!.todayCompletedTasks}/${_summary!.todayTotalTasks}',
                                  style: FontStyles.med14.copyWith(
                                    color: ColorStyles.grey1,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // 할 일 목록
                          if (!_tasksInitiallyLoaded ||
                              (displayTasks.isEmpty && _fullTasksFetching))
                            _buildTaskListSkeleton()
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
                            if (_isExpanded && _fullTasksFetching)
                              _buildTaskListSkeleton(),
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
