import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:project_daon/checklist/widget/calBottomPopup.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'dart:ui';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistWeekWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const ChecklistWeekWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<ChecklistWeekWidget> createState() => _ChecklistWeekWidgetState();
}

class _ChecklistWeekWidgetState extends State<ChecklistWeekWidget> {
  late DateTime _currentWeekStart;
  final DateTime _today = DateTime.now();
  final List<String> _weekDays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getStartOfWeek(widget.selectedDate);
  }

  // 부모로부터 선택 날짜가 강제로 변경되었을 때 달력 표시 주차도 동기화
  @override
  void didUpdateWidget(covariant ChecklistWeekWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      setState(() {
        _currentWeekStart = _getStartOfWeek(widget.selectedDate);
      });
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday % 7;
    return date.subtract(Duration(days: daysToSubtract));
  }

  String _getWeekOfMonthText(DateTime date) {
    DateTime thursday = date.add(
      Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)),
    );

    DateTime firstDayOfMonth = DateTime(thursday.year, thursday.month, 1);
    int weekNum = ((thursday.day + firstDayOfMonth.weekday - 1) / 7).ceil();

    List<String> weekKorean = ['첫째', '둘째', '셋째', '넷째', '다섯째', '여섯째'];
    String weekString = weekNum <= weekKorean.length
        ? weekKorean[weekNum - 1]
        : '${weekNum}째';

    return '${thursday.month}월 $weekString 주';
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: SvgPicture.asset('assets/checklist/arrowL.svg'),
              onPressed: _previousWeek,
            ),
            // 💡 월간 달력 위젯 호출 부분 수정
            TextButton(
              onPressed: () async {
                // 바텀 시트 호출 및 결과(DateTime) 대기
                final DateTime? newSelectedWeek =
                    await showModalBottomSheet<DateTime>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor:
                          Colors.transparent, // 팝업의 둥근 모서리를 살리기 위해 투명 처리
                      builder: (context) {
                        return CalWeekSelectionPopupWidget(
                          initialDate: _currentWeekStart, // 현재 표시 중인 날짜 전달
                        );
                      },
                    );

                // 팝업에서 '선택하기'를 눌러 날짜를 받아왔다면
                if (newSelectedWeek != null) {
                  setState(() {
                    _currentWeekStart = newSelectedWeek; // 달력을 선택한 주차로 이동
                  });
                  // 부모 위젯(ChecklistPage)의 상태도 해당 주의 일요일로 업데이트
                  widget.onDateSelected(newSelectedWeek);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: Text(
                _getWeekOfMonthText(_currentWeekStart),
                style: FontStyles.semi20,
              ),
            ),
            IconButton(
              icon: SvgPicture.asset('assets/checklist/arrowR.svg'),
              onPressed: _nextWeek,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              DateTime currentDate = _currentWeekStart.add(
                Duration(days: index),
              );
              bool isToday = _isSameDay(currentDate, _today);
              bool isSelected = _isSameDay(currentDate, widget.selectedDate);

              return GestureDetector(
                onTap: () {
                  widget.onDateSelected(currentDate);
                },
                child: CustomPaint(
                  painter: (isSelected && !isToday)
                      ? DottedBorderPainter(color: ColorStyles.main1)
                      : null,
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      color: isToday ? ColorStyles.main1 : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weekDays[index],
                          style: FontStyles.med15.copyWith(
                            color: isToday
                                ? ColorStyles.white
                                : ColorStyles.black2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentDate.day}',
                          style: FontStyles.med15.copyWith(
                            color: isToday
                                ? ColorStyles.white
                                : ColorStyles.black2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;

  DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(10.0),
        ),
      );

    PathMetrics pathMetrics = path.computeMetrics();
    Path dashPath = Path();

    const double dashWidth = 3.0;
    const double dashSpace = 3.0;

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
