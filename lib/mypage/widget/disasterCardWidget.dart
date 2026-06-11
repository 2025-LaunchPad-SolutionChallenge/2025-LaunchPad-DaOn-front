import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/mypage/widget/myPageDropdown.dart';
import 'package:project_daon/ui/colorStyles.dart';

// GET /api/v1/disasters 응답에는 location/damageDetail 필드가 없습니다.
// GET /api/v1/disasters/{id} 응답에도 location/damageDetail이 없어
// 두 항목은 현재 fallback 텍스트로 표시됩니다.
class DisasterCardWidget extends StatelessWidget {
  final List<UserDisasterSummary> records;
  final int? selectedId;
  final ValueChanged<int> onDisasterSelected;
  final VoidCallback onAddDisaster;

  const DisasterCardWidget({
    Key? key,
    required this.records,
    this.selectedId,
    required this.onDisasterSelected,
    required this.onAddDisaster,
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

  @override
  Widget build(BuildContext context) {
    // userDisasterId 기준으로 중복 제거
    final seen = <int>{};
    final unique = records
        .where((r) => seen.add(r.userDisasterId))
        .toList();

    final ids = unique.map((r) => r.userDisasterId).toList();
    final labels = unique.map((r) => r.displayLabel).toList();

    // selectedId가 목록에 없으면 첫 번째 항목으로 fallback
    final validSelectedId =
        (selectedId != null && ids.contains(selectedId))
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
        color: Colors.white,
        border: Border.all(color: ColorStyles.main2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 드롭다운 + + 버튼 + 상태 레이블 ──
          Row(
            children: [
              Expanded(
                child: MyPageDropdown(
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
              ),
              const SizedBox(width: 8),
              // 재난 추가 + 버튼
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
              const SizedBox(width: 12),
              // 상태 레이블
              Text(
                _statusLabel(selected.status),
                style: const TextStyle(
                  color: ColorStyles.main2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 장소 (API 미제공 → fallback)
          const Text(
            '장소 정보 없음',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          // 피해 정도 (API 미제공 → fallback)
          const Text(
            '피해 정도: 등록된 피해 정보 없음',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 17),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorStyles.main2,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text(
                '회복 대시보드',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
