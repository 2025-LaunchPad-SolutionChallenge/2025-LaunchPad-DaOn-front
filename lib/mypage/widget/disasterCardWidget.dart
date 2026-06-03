import 'package:flutter/material.dart';
import 'package:project_daon/mypage/model/disasterRecord.dart';
import 'package:project_daon/mypage/widget/myPageDropdown.dart';
import 'package:project_daon/ui/colorStyles.dart';
// 위에서 만든 Dropdown 위젯 import 해주세요
// import 'package:project_daon/mypage/widget/dropdown.dart';

class DisasterCardWidget extends StatefulWidget {
  final List<DisasterRecord> records;

  const DisasterCardWidget({Key? key, required this.records}) : super(key: key);

  @override
  State<DisasterCardWidget> createState() => _DisasterCardWidgetState();
}

class _DisasterCardWidgetState extends State<DisasterCardWidget> {
  late DisasterRecord _selectedRecord;

  @override
  void initState() {
    super.initState();
    _selectedRecord = widget.records.first; // 기본값으로 첫 번째 선택
  }

  @override
  void didUpdateWidget(covariant DisasterCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상단 탭이 변경되어 새로운 리스트가 오면 다시 첫 번째 항목으로 초기화
    if (widget.records != oldWidget.records) {
      _selectedRecord = widget.records.first;
    }
  }

  String _getStatusText(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recovering:
        return '회복 중';
      case RecoveryStatus.completed:
        return '회복 완료';
      case RecoveryStatus.archived:
        return '보관';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dropdown에 전달할 String 리스트 생성 ('홍수 피해 / 2025 - 02 - 24' 형태)
    final List<String> dropdownItems = widget.records
        .map((r) => '${r.title}  |  ${r.date}')
        .toList();
    final String currentDropdownValue =
        '${_selectedRecord.title}  |  ${_selectedRecord.date}';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyPageDropdown(
                items: dropdownItems,
                selectedValue: currentDropdownValue,
                color: 'main1',
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRecord = widget.records.firstWhere(
                        (r) => '${r.title}  |  ${r.date}' == newValue,
                      );
                    });
                  }
                },
              ),
              // 우측 상단 상태 텍스트
              Text(
                _getStatusText(_selectedRecord.status),
                style: const TextStyle(
                  color: ColorStyles.main2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedRecord.location,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '피해 정도 : ${_selectedRecord.damageDetail}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
