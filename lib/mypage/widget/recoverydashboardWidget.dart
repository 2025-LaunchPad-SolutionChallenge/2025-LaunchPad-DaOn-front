import 'package:flutter/material.dart';
import 'package:project_daon/mypage/model/disasterRecord.dart';
import 'package:project_daon/mypage/widget/disasterCardWidget.dart';
import 'package:project_daon/mypage/widget/stateToggleWidget.dart';
import 'package:project_daon/ui/fontStyles.dart';
import 'package:project_daon/ui/colorStyles.dart';

class RecoveryDashboardWidget extends StatefulWidget {
  const RecoveryDashboardWidget({Key? key}) : super(key: key);

  @override
  State<RecoveryDashboardWidget> createState() =>
      _RecoveryDashboardWidgetState();
}

class _RecoveryDashboardWidgetState extends State<RecoveryDashboardWidget> {
  // 초기 상태는 '회복 중'
  RecoveryStatus _currentStatus = RecoveryStatus.recovering;

  // 테스트용 더미 데이터 (회복 중인 재난이 2개라고 가정)
  final List<DisasterRecord> _records = [
    DisasterRecord(
      title: '홍수 피해',
      date: '2025 - 02 - 24',
      location: '용산구 일대',
      damageDetail: '주거 공간 피해, 차량 피해',
      status: RecoveryStatus.recovering,
    ),
    DisasterRecord(
      title: '태풍 피해',
      date: '2025 - 08 - 12',
      location: '강남구 일대',
      damageDetail: '창문 파손, 간판 추락',
      status: RecoveryStatus.recovering,
    ),
    DisasterRecord(
      title: '화재 피해',
      date: '2024 - 11 - 10',
      location: '마포구 일대',
      damageDetail: '상가 전소',
      status: RecoveryStatus.completed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _records
        .where((record) => record.status == _currentStatus)
        .toList();

    return Column(
      children: [
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
                setState(() {
                  _currentStatus = newStatus; // 상태 업데이트 및 UI 재빌드
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 30),

        if (filteredRecords.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 40.0),
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
          DisasterCardWidget(records: filteredRecords),
      ],
    );
  }
}
