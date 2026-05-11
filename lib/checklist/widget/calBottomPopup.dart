import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class CalWeekSelectionPopupWidget extends StatefulWidget {
  final DateTime initialDate; // 달력 위젯에서 현재 가리키고 있는 날짜 (디폴트 값)

  const CalWeekSelectionPopupWidget({super.key, required this.initialDate});

  @override
  State<CalWeekSelectionPopupWidget> createState() =>
      _CalWeekSelectionPopupWidgetState();
}

class _CalWeekSelectionPopupWidgetState
    extends State<CalWeekSelectionPopupWidget> {
  late DateTime _displayedMonth;
  late DateTime _selectedWeekStart;
  final DateTime _today = DateTime.now();

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _weekDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void initState() {
    super.initState();
    // 초기 디폴트 주차 및 표시할 월 설정
    _selectedWeekStart = _getStartOfWeek(widget.initialDate);
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  // 일요일 기준 주의 시작일 계산
  DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday % 7; // 일요일은 0, 월요일은 1 ...
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 년/월을 모두 선택할 수 있는 커스텀 다이얼로그
  void _showMonthYearPicker() async {
    // 다이얼로그 내에서 임시로 관리할 상태값
    int tempYear = _displayedMonth.year;

    await showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder를 사용하여 다이얼로그 내에서도 setState가 작동하게 합니다.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 년도 선택 헤더 (이전/다음 버튼)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setDialogState(() => tempYear--),
                      ),
                      Text(
                        '$tempYear',
                        style: FontStyles.semi20.copyWith(
                          color: ColorStyles.black1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setDialogState(() => tempYear++),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 2. 1월~12월 그리드 선택창
                  SizedBox(
                    width: 300,
                    height: 200,
                    child: GridView.builder(
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // 4열 배치
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                      itemBuilder: (context, index) {
                        int month = index + 1;
                        bool isCurrentMonth =
                            tempYear == _displayedMonth.year &&
                            month == _displayedMonth.month;

                        return GestureDetector(
                          onTap: () {
                            // 선택한 년도와 월을 실제 상태에 반영하고 닫기
                            setState(() {
                              _displayedMonth = DateTime(tempYear, month, 1);
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrentMonth
                                  ? ColorStyles.main1
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentMonth
                                    ? ColorStyles.main1
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Text(
                              '$month월',
                              style: TextStyle(
                                color: isCurrentMonth
                                    ? Colors.white
                                    : ColorStyles.black2,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
          },
        );
      },
    );
  }

  // 달력의 각 행(주차)을 빌드하는 함수
  List<Widget> _buildCalendarWeeks() {
    List<Widget> weeks = [];

    // 현재 달의 1일
    DateTime firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    // 현재 달의 마지막 일
    DateTime lastDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );

    // 달력 시작일 (1일이 속한 주의 일요일)
    DateTime startDate = _getStartOfWeek(firstDayOfMonth);
    DateTime currentDate = startDate;

    // 6주차까지 생성 (최대 필요한 행의 수)
    for (int i = 0; i < 6; i++) {
      // 해당 행이 현재 월의 데이터를 전혀 포함하지 않으면 그리지 않음
      if (i > 0 && currentDate.isAfter(lastDayOfMonth)) break;

      DateTime thisWeekStart = currentDate;
      bool isSelectedWeek = _isSameDay(thisWeekStart, _selectedWeekStart);

      List<Widget> days = [];
      for (int j = 0; j < 7; j++) {
        bool isCurrentMonth = currentDate.month == _displayedMonth.month;
        bool isToday = _isSameDay(currentDate, _today);
        DateTime dayToPass = currentDate;

        days.add(
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedWeekStart = _getStartOfWeek(dayToPass);
                });
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child:
                    isCurrentMonth ||
                        isSelectedWeek // 현재 달이거나, 선택된 주차의 일부일 때만 표시
                    ? Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF59A57F)
                              : Colors.transparent, // 오늘이면 진한 녹색
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${currentDate.day}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isToday
                                ? Colors.white
                                : (isCurrentMonth
                                      ? ColorStyles.black1
                                      : Colors.grey),
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      )
                    : const SizedBox(), // 다른 달의 날짜는 숨김
              ),
            ),
          ),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 주차(Row) 위젯 추가
      weeks.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            // 선택된 주차일 경우 행 전체에 연한 녹색 배경 적용
            color: isSelectedWeek
                ? const Color(0xFFEFF7F3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days,
          ),
        ),
      );
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 30.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 드래그 핸들 (상단 회색 바)
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: ShapeDecoration(
                  color: const Color(0x33525252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // 2. 월/연도 헤더 (터치 시 팝업)
            GestureDetector(
              onTap: _showMonthYearPicker,
              child: Row(
                children: [
                  Text(
                    '${_monthNames[_displayedMonth.month - 1]}, ${_displayedMonth.year}',
                    style: FontStyles.semi20.copyWith(
                      color: ColorStyles.black1,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // 3. 요일 헤더 (Sun, Mon ...)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12.0),

            // 4. 달력 날짜 영역 (주차 단위 렌더링)
            ..._buildCalendarWeeks(),

            const SizedBox(height: 32.0),

            // 5. 하단 선택 버튼
            GradientButton(
              text: '선택하기',
              onPressed: () {
                // 선택된 주차의 시작일(일요일)을 부모에게 전달하며 바텀시트 닫기
                Navigator.pop(context, _selectedWeekStart);
              },
            ),
          ],
        ),
      ),
    );
  }
}
