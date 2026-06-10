import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_daon/common/widget/DetailAppBar.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/common/widget/expandSectionWidget.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistAiAddPage extends StatefulWidget {
  final DateTime selectedDate;
  final int? initialUserDisasterId;

  const ChecklistAiAddPage({
    super.key,
    required this.selectedDate,
    this.initialUserDisasterId,
  });

  @override
  State<ChecklistAiAddPage> createState() => _ChecklistAiAddPageState();
}

class _ChecklistAiAddPageState extends State<ChecklistAiAddPage> {
  final Dio _dio = AuthService().dio;
  final TextEditingController _specialNotesController = TextEditingController();

  List<_DisasterOption> _disasters = [];
  int? _selectedDisasterIndex;
  bool? _canGoOut;
  String? _selectedTimeLabel;
  bool _isLoadingDisasters = true;
  bool _isSubmitting = false;

  static const Map<String, String> _timeEnumMap = {
    '1시간 미만': 'UNDER_ONE_HOUR',
    '1~3시간': 'ONE_TO_THREE_HOURS',
    '반나절 이상': 'ALL_DAY_HALF_DAY',
  };

  @override
  void initState() {
    super.initState();
    _loadDisasters();
  }

  @override
  void dispose() {
    _specialNotesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<void> _loadDisasters() async {
    try {
      final response = await _dio.get(
        '/api/v1/disasters',
        queryParameters: {'page': 0, 'size': 20},
      );

      final data = _asMap(response.data);
      final content = data['content'] is List
          ? data['content'] as List
          : const [];
      final disasters = content
          .map((item) => _DisasterOption.fromJson(_asMap(item)))
          .where((item) => item.userDisasterId != null)
          .toList();

      int? initialIndex;
      if (widget.initialUserDisasterId != null) {
        final idx = disasters.indexWhere(
          (item) => item.userDisasterId == widget.initialUserDisasterId,
        );
        if (idx != -1) initialIndex = idx;
      }

      if (!mounted) return;
      setState(() {
        _disasters = disasters;
        _selectedDisasterIndex = disasters.isEmpty ? null : (initialIndex ?? 0);
        _isLoadingDisasters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDisasters = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재난 목록을 불러오지 못했습니다.')));
      debugPrint('[AI 체크리스트] 재난 목록 조회 실패: $e');
    }
  }

  bool get _canSubmit {
    return !_isSubmitting &&
        _selectedDisasterIndex != null &&
        _canGoOut != null &&
        _selectedTimeLabel != null;
  }

  Future<void> _saveContext({
    required int userDisasterId,
    required bool canGoOut,
    required String availableTime,
    required String specialNotes,
  }) async {
    await _dio.post(
      '/api/v1/checklists/context',
      data: {
        'userDisasterId': userDisasterId,
        'userCondition': {
          'canGoOut': canGoOut,
          'availableTime': availableTime,
          'specialNotes': specialNotes,
        },
      },
    );
  }

  Future<void> _generateAiChecklist({
    required int userDisasterId,
    required DateTime targetDate,
  }) async {
    final targetDateText = _formatDate(targetDate);
    debugPrint(
      '[AI 체크리스트] 생성 요청: userDisasterId=$userDisasterId targetDate=$targetDateText',
    );

    await _dio.post(
      '/api/v1/checklists/ai-generate',
      data: {'userDisasterId': userDisasterId, 'targetDate': targetDateText},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필수 항목을 모두 선택해 주세요.')));
      return;
    }

    final selectedDisaster = _disasters[_selectedDisasterIndex!];
    final userDisasterId = selectedDisaster.userDisasterId;
    final selectedTime = _selectedTimeLabel;

    if (userDisasterId == null || selectedTime == null) return;

    final availableTime = _timeEnumMap[selectedTime];
    if (availableTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('외출 가능 시간 값을 확인해 주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _saveContext(
        userDisasterId: userDisasterId,
        canGoOut: _canGoOut!,
        availableTime: availableTime,
        specialNotes: _specialNotesController.text.trim(),
      );

      await _generateAiChecklist(
        userDisasterId: userDisasterId,
        targetDate: widget.selectedDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 체크리스트가 생성되었습니다.')));
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 생성이 오래 걸리고 있어요. 잠시 후 목록을 다시 확인해 주세요.'),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      final data = e.response?.data;
      debugPrint('[AI 체크리스트] 생성 실패: $data');
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 체크리스트 생성에 실패했습니다.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      debugPrint('[AI 체크리스트] 생성 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 체크리스트 생성에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final disasterLabels = _disasters.map((item) => item.displayLabel).toList();

    return Scaffold(
      backgroundColor: ColorStyles.white,
      appBar: DetailAppBar(),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '나의 재난',
                        style: FontStyles.semi16.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      _isLoadingDisasters
                          ? const SizedBox(
                              height: 42,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Dropdown(
                              color: 'main1',
                              items: disasterLabels.isNotEmpty
                                  ? disasterLabels
                                  : ['재난 정보 없음'],
                              initialIndex: _selectedDisasterIndex ?? 0,
                              onIndexChanged: (index) {
                                if (index < 0 || index >= _disasters.length) {
                                  return;
                                }
                                setState(() => _selectedDisasterIndex = index);
                              },
                            ),
                      const SizedBox(height: 16.0),
                      Text(
                        '재난 상황을 입력해주세요.\n상황에 맞춰서 AI가 체크리스트를 생성합니다.',
                        style: FontStyles.med15.copyWith(
                          color: ColorStyles.black2,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ExpandSectionWidget(
                        title: '오늘 외출 가능 여부',
                        options: const ['가능', '불가능'],
                        selectedValue: _canGoOut == null
                            ? null
                            : _canGoOut!
                            ? '가능'
                            : '불가능',
                        onChanged: (value) {
                          setState(
                            () => _canGoOut = value == null
                                ? null
                                : value == '가능',
                          );
                        },
                      ),
                      ExpandSectionWidget(
                        title: '외출 가능 시간',
                        options: _timeEnumMap.keys.toList(),
                        selectedValue: _selectedTimeLabel,
                        onChanged: (value) {
                          setState(() => _selectedTimeLabel = value);
                        },
                      ),
                      ExpandSectionWidget(
                        title: '특이 사항 입력',
                        isTextInput: true,
                        controller: _specialNotesController,
                        hintText: '특이 사항을 입력해주세요.',
                        hintSize: 14.0,
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _canSubmit ? _onSubmit : null,
                child: Opacity(
                  opacity: _canSubmit ? 1.0 : 0.45,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorStyles.main2,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : GradientButton(text: '생성하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisasterOption {
  final int? userDisasterId;
  final String title;
  final String disasterTypeName;
  final String occurredAt;

  const _DisasterOption({
    required this.userDisasterId,
    required this.title,
    required this.disasterTypeName,
    required this.occurredAt,
  });

  factory _DisasterOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['userDisasterId'];
    return _DisasterOption(
      userDisasterId: rawId is int
          ? rawId
          : rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      disasterTypeName: json['disasterTypeName']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
    );
  }

  String get displayLabel {
    final name = disasterTypeName.isNotEmpty
        ? disasterTypeName
        : title.isNotEmpty
        ? title
        : '재난';
    final date = _formatOccurredAt(occurredAt);
    return date.isEmpty ? name : '$name 피해  |  $date';
  }

  String _formatOccurredAt(String value) {
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$year - $month - $day';
  }
}
