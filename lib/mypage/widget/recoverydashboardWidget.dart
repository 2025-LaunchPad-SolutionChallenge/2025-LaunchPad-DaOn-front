import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/mypage/view/recoveryGraphPage.dart';
import 'package:project_daon/mypage/widget/disasterCardWidget.dart';
import 'package:project_daon/mypage/widget/stateToggleWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class RecoveryDashboardWidget extends StatefulWidget {
  final List<UserDisasterSummary> disasters;
  final int? selectedDisasterId;
  final ValueChanged<int> onDisasterSelected;
  final VoidCallback onAddDisaster;
  final void Function(int id, String action)? onCloseDisaster;

  const RecoveryDashboardWidget({
    Key? key,
    required this.disasters,
    this.selectedDisasterId,
    required this.onDisasterSelected,
    required this.onAddDisaster,
    this.onCloseDisaster,
  }) : super(key: key);

  @override
  State<RecoveryDashboardWidget> createState() =>
      _RecoveryDashboardWidgetState();
}

class _RecoveryDashboardWidgetState extends State<RecoveryDashboardWidget> {
  // '전체' | 'ACTIVE' | 'EXPIRED' | 'ARCHIVED'
  String _currentStatus = '전체';

  List<UserDisasterSummary> get _filteredRecords {
    if (_currentStatus == '전체') return widget.disasters;
    return widget.disasters.where((d) => d.status == _currentStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '[마이페이지] RecoveryDashboardWidget build, count=${widget.disasters.length}',
      );
    }

    final filteredRecords = _filteredRecords;

    return Column(
      children: [
        // ── 헤더 Row: 제목 + StateToggleWidget ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '나의 재난 확인하기',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            StateToggleWidget(
              currentStatus: _currentStatus,
              onStatusChanged: (newStatus) {
                if (kDebugMode) debugPrint('[재난] 상태 필터 변경: $newStatus');
                setState(() => _currentStatus = newStatus);
                // 필터 변경 후 선택 재난이 새 목록에 없으면 첫 번째로 자동 선택
                final newFiltered = newStatus == '전체'
                    ? widget.disasters
                    : widget.disasters
                          .where((d) => d.status == newStatus)
                          .toList();
                if (newFiltered.isNotEmpty) {
                  final currentId = widget.selectedDisasterId;
                  if (currentId == null ||
                      !newFiltered.any((d) => d.userDisasterId == currentId)) {
                    widget.onDisasterSelected(newFiltered.first.userDisasterId);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (filteredRecords.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            width: double.infinity,
            height: 190,
            child: Center(
              child: Text(
                '해당 상태의 재난 내역이 없습니다.',
                style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
              ),
            ),
          )
        else
          DisasterCardWidget(
            records: filteredRecords,
            selectedId: widget.selectedDisasterId,
            onDisasterSelected: widget.onDisasterSelected,
            onAddDisaster: widget.onAddDisaster,
            onCloseDisaster: widget.onCloseDisaster,
            onDashboardTap: (id) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecoveryGraphPage(userDisasterId: id),
                ),
              );
            },
          ),
      ],
    );
  }
}
