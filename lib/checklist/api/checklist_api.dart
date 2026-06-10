import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/core/service/auth_service.dart';

class ChecklistResult {
  final List<ChecklistItemModel> items;
  final double completionRate;
  ChecklistResult({required this.items, required this.completionRate});
}

class ChecklistApi {
  final Dio _dio = AuthService().dio;

  static String _fmtDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<ChecklistResult> fetchChecklist(
    int userDisasterId,
    DateTime date,
  ) async {
    final dateStr = _fmtDate(date);
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] GET /api/v1/disasters/$userDisasterId/checklist?date=$dateStr',
      );
    }
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/checklist',
      queryParameters: {'date': dateStr},
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] GET 응답 status=${response.statusCode} data=${response.data}');
    }
    final data = response.data;
    List<dynamic> raw = [];
    double completionRate = 0.0;
    if (data is Map) {
      completionRate = (data['completionRate'] as num?)?.toDouble() ?? 0.0;
      final days = data['days'];
      if (days is List) {
        for (final day in days) {
          if (day is Map && day['checklistDate'] == dateStr) {
            raw = (day['items'] as List?) ?? [];
            break;
          }
        }
        if (raw.isEmpty && days.isNotEmpty && days.first is Map) {
          raw = ((days.first as Map)['items'] as List?) ?? [];
        }
      } else if (days is Map) {
        final dayData = days[dateStr];
        if (dayData is Map) {
          raw = (dayData['items'] as List?) ?? [];
        } else if (dayData is List) {
          raw = dayData;
        }
      }
    } else if (data is List) {
      raw = data;
    }
    final items = raw
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ChecklistResult(items: items, completionRate: completionRate);
  }

  Future<int> addChecklistItem({
    required int userDisasterId,
    required String title,
    required String checklistDate,
    int priority = 2,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] POST /api/v1/disasters/$userDisasterId/checklist '
        'body={title: $title, checklistDate: $checklistDate, priority: $priority}',
      );
    }
    final response = await _dio.post(
      '/api/v1/disasters/$userDisasterId/checklist',
      data: {
        'title': title,
        'checklistDate': checklistDate,
        'priority': priority,
      },
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] POST 추가 응답: ${response.statusCode} ${response.data}');
    }
    final rawData = response.data;
    final id = rawData is Map
        ? ((rawData['checklistItemId']) as num?)?.toInt() ?? 0
        : 0;
    return id;
  }

  Future<void> editChecklistItem({
    required int userDisasterId,
    required int checklistItemId,
    required String title,
    required String checklistDate,
    required bool isCompleted,
    int priority = 2,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH /api/v1/disasters/$userDisasterId/checklist/$checklistItemId '
        'body={title: $title, checklistDate: $checklistDate, isCompleted: $isCompleted, priority: $priority}',
      );
    }
    final response = await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
      data: {
        'title': title,
        'checklistDate': checklistDate,
        'isCompleted': isCompleted,
        'priority': priority,
      },
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] PATCH 편집 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<void> updateChecklistStatus({
    required int userDisasterId,
    required int checklistItemId,
    required bool isCompleted,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] PATCH /api/v1/disasters/$userDisasterId/checklist/$checklistItemId/status '
        'body={isCompleted: $isCompleted}',
      );
    }
    final response = await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/status',
      data: {'isCompleted': isCompleted},
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] PATCH 상태 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<void> deleteChecklistItem({
    required int userDisasterId,
    required int checklistItemId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[체크리스트] DELETE /api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
      );
    }
    final response = await _dio.delete(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId',
    );
    if (kDebugMode) {
      debugPrint('[체크리스트] DELETE 응답: ${response.statusCode} ${response.data}');
    }
  }

  Future<void> saveContext({
    required int userDisasterId,
    required bool canGoOut,
    required String availableTime,
    required String specialNotes,
  }) async {
    if (kDebugMode) debugPrint('[체크리스트] 컨텍스트 저장');
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

  Future<void> generateAiChecklist({
    required int userDisasterId,
    required DateTime date,
  }) async {
    final dateStr = _fmtDate(date);
    if (kDebugMode) {
      debugPrint('[체크리스트] AI 생성 요청: disasterId=$userDisasterId date=$dateStr');
    }
    try {
      await _dio.post(
        '/api/v1/checklists/ai-generate',
        data: {'userDisasterId': userDisasterId, 'targetDate': dateStr},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.receiveTimeout) rethrow;
      if (kDebugMode) debugPrint('[체크리스트] AI 생성 응답 대기 시간 초과 (정상)');
    }
  }

  ChecklistItemModel _itemFromJson(Map<String, dynamic> json) {
    final checklistItemId =
        ((json['checklistItemId'] ?? json['id']) as num?)?.toInt() ?? 0;
    return ChecklistItemModel(
      checklistItemId: checklistItemId,
      title: json['title']?.toString() ?? '',
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      isChecked: json['isCompleted'] as bool? ?? false,
      memo: json['memo']?.toString(),
      priority: (json['priority'] as num?)?.toInt() ?? 2,
      checklistDate: json['checklistDate']?.toString(),
    );
  }
}
