import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/mypage/api/recoveryApi.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class RecoveryGraphPage extends StatefulWidget {
  final int userDisasterId;

  const RecoveryGraphPage({super.key, required this.userDisasterId});

  @override
  State<RecoveryGraphPage> createState() => _RecoveryGraphPageState();
}

class _RecoveryGraphPageState extends State<RecoveryGraphPage> {
  final RecoveryApi _api = RecoveryApi();

  bool _isLoading = true;
  List<RecoveryGraphPoint> _graphPoints = [];
  List<TimelineChecklistDay> _timelineDays = [];
  late DateTime _startDate;
  late DateTime _endDate;
  String? _graphError;
  String? _timelineError;

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDisplay(DateTime d) => '${d.year}.${d.month}.${d.day}';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // 3개월 전: Dart DateTime이 월 음수값을 연도로 올바르게 보정함
    _startDate = today.subtract(const Duration(days: 30));
    _endDate = today;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    RecoveryGraphResponse? graphResponse;
    TimelineChecklistResponse? timelineResponse;
    String? graphError;
    String? timelineError;

    final startStr = _fmtDate(_startDate);
    final endStr = _fmtDate(_endDate);

    await Future.wait([
      () async {
        try {
          graphResponse = await _api.fetchRecoveryGraph(widget.userDisasterId);
        } catch (e) {
          if (kDebugMode) debugPrint('[회복그래프] 오류: $e');
          graphError = e.toString();
        }
      }(),
      () async {
        try {
          timelineResponse = await _api.fetchTimelineChecklist(
            widget.userDisasterId,
            startDate: startStr,
            endDate: endStr,
          );
        } catch (e) {
          if (kDebugMode) debugPrint('[타임라인] 오류: $e');
          timelineError = e.toString();
        }
      }(),
    ]);

    if (!mounted) return;

    // 3개월 범위 필터링 (API가 더 넓은 범위를 반환할 경우 대비)
    final filteredPoints =
        graphResponse?.points.where((p) {
          try {
            final d = DateTime.parse(p.date);
            return !d.isBefore(_startDate) && !d.isAfter(_endDate);
          } catch (_) {
            return false;
          }
        }).toList() ??
        [];

    // 날짜 내림차순 정렬 (최신 날짜 먼저)
    final sortedDays = List<TimelineChecklistDay>.from(
      timelineResponse?.days ?? [],
    )..sort((a, b) => b.checklistDate.compareTo(a.checklistDate));

    setState(() {
      _graphPoints = filteredPoints;
      _timelineDays = sortedDays;
      _graphError = graphError;
      _timelineError = timelineError;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorStyles.black1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '회복 그래프',
          style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ColorStyles.main2),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fmtDisplay(_startDate)} ~ ${_fmtDisplay(_endDate)}',
                    style: FontStyles.med14.copyWith(color: ColorStyles.main1),
                  ),
                  const SizedBox(height: 16),
                  _buildGraph(),
                  const SizedBox(height: 32),
                  Text(
                    'Timeline',
                    style: FontStyles.semi20.copyWith(
                      color: ColorStyles.black1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeline(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGraph() {
    if (_graphError != null && _graphPoints.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          '그래프를 불러오지 못했습니다.',
          style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
        ),
      );
    }

    if (_graphPoints.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          '아직 회복 그래프 데이터가 없습니다.',
          style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
        ),
      );
    }

    final maxX = _endDate.difference(_startDate).inDays.toDouble();
    final spots = _graphPoints.map((p) {
      final d = DateTime.parse(p.date);
      final x = d.difference(_startDate).inDays.toDouble().clamp(0.0, maxX);
      final y = p.recoveryScore.clamp(0.0, 100.0);
      return FlSpot(x, y);
    }).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: ColorStyles.grey2,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 30,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final labelDate = _startDate.add(
                    Duration(days: value.toInt()),
                  );
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${labelDate.month}월',
                      style: FontStyles.med12.copyWith(
                        color: ColorStyles.grey1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 1,
              curveSmoothness: 0.3,
              color: ColorStyles.main2,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: ColorStyles.main2.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_timelineError != null && _timelineDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '타임라인을 불러오지 못했습니다.',
            style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
          ),
        ),
      );
    }

    if (_timelineDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '아직 타임라인 데이터가 없습니다.',
            style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
          ),
        ),
      );
    }

    return Column(children: _timelineDays.map(_buildDaySection).toList());
  }

  Widget _buildDaySection(TimelineChecklistDay day) {
    String dateLabel;
    try {
      final d = DateTime.parse(day.checklistDate);
      dateLabel = '${d.month}.${d.day}';
    } catch (_) {
      dateLabel = day.checklistDate;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        tilePadding: const EdgeInsets.symmetric(vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Text(
              dateLabel,
              style: FontStyles.semi16.copyWith(color: ColorStyles.black2),
            ),
            const SizedBox(width: 8),
            Text(
              '${day.completed}/${day.total}',
              style: FontStyles.med12.copyWith(color: ColorStyles.grey1),
            ),
          ],
        ),
        children: day.items.map(_buildChecklistItem).toList(),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(TimelineChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
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
          Expanded(
            child: Text(
              item.title,
              style: FontStyles.med14.copyWith(
                color: item.isCompleted
                    ? ColorStyles.black2.withOpacity(0.45)
                    : ColorStyles.black2,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
