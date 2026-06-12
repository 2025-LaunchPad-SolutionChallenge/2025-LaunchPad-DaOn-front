import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/mypage/widget/myPageDropdown.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class DisasterCardWidget extends StatelessWidget {
  final List<UserDisasterSummary> records;
  final int? selectedId;
  final ValueChanged<int> onDisasterSelected;
  final VoidCallback onAddDisaster;
  final ValueChanged<int>? onDashboardTap;
  final void Function(int id, String action)? onCloseDisaster;

  const DisasterCardWidget({
    Key? key,
    required this.records,
    this.selectedId,
    required this.onDisasterSelected,
    required this.onAddDisaster,
    this.onDashboardTap,
    this.onCloseDisaster,
  }) : super(key: key);

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return '회복 중';
      case 'EXPIRED':
        return '회복 완료';
      case 'ARCHIVED':
        return '보관';
      default:
        return status;
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seen = <int>{};
    final unique = records.where((r) => seen.add(r.userDisasterId)).toList();

    final ids = unique.map((r) => r.userDisasterId).toList();
    final labels = unique.map((r) => r.displayLabel).toList();

    final validSelectedId = (selectedId != null && ids.contains(selectedId))
        ? selectedId
        : (ids.isNotEmpty ? ids.first : null);

    final selected = unique.firstWhere(
      (r) => r.userDisasterId == validSelectedId,
      orElse: () => unique.first,
    );

    if (kDebugMode) {
      debugPrint(
        '[재난] 카드 표시: unique=${unique.length}개, selectedId=$validSelectedId',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorStyles.white,
        border: Border.all(color: ColorStyles.main2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 드롭다운 + + 버튼 + 상태 레이블 ──
          Row(
            children: [
              MyPageDropdown(
                ids: ids,
                labels: labels,
                selectedId: validSelectedId,
                color: 'main1',
                onChanged: (id) {
                  if (id == null) return;
                  if (kDebugMode) {
                    debugPrint('[재난] 선택 변경: userDisasterId=$id');
                  }
                  onDisasterSelected(id);
                },
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: '재난 추가',
                child: InkWell(
                  onTap: onAddDisaster,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorStyles.main1),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: ColorStyles.main1,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _statusLabel(selected.status),
                    style: FontStyles.med14.copyWith(color: ColorStyles.main2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selected.address != null && selected.address!.isNotEmpty) ...[
            Text(
              selected.address!,
              style: FontStyles.med12.copyWith(color: ColorStyles.grey1),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '회복률: ${selected.recoveryProgress.toStringAsFixed(1)}%',
            style: FontStyles.med16.copyWith(color: ColorStyles.black2),
          ),
          const SizedBox(height: 17),
          // ── 상태 변경 버튼 + 회복 대시보드 버튼 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selected.status == 'ACTIVE') ...[
                _buildIconButton(
                  icon: Icons.check_circle_outline,
                  tooltip: '회복 완료',
                  color: ColorStyles.main2,
                  onTap: () =>
                      onCloseDisaster?.call(selected.userDisasterId, 'CLOSE'),
                ),
                const SizedBox(width: 8),
              ],
              if (selected.status != 'ARCHIVED') ...[
                _buildIconButton(
                  icon: Icons.archive_outlined,
                  tooltip: '보관',
                  color: ColorStyles.grey1,
                  onTap: () =>
                      onCloseDisaster?.call(selected.userDisasterId, 'ARCHIVE'),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: validSelectedId != null
                    ? () => onDashboardTap?.call(validSelectedId)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorStyles.main2,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text(
                  '회복 대시보드',
                  style: FontStyles.med16.copyWith(color: ColorStyles.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
