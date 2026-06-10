import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/core/service/auth_service.dart';

class ChecklistApi {
  final Dio _dio = AuthService().dio;

  Future<List<ChecklistItemModel>> getChecklistItems(
    int userDisasterId,
    DateTime date,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    print('[체크리스트] 목록 조회: disasterId=$userDisasterId date=$dateStr');
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/checklist',
      queryParameters: {'date': dateStr},
    );
    final data = response.data;
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
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
    }
    return raw
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (kDebugMode)
      debugPrint('[체크리스트] AI 생성 요청: disasterId=$userDisasterId date=$dateStr');
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
    final id = (json['checklistItemId'] ?? json['id'] ?? 0).toString();
    return ChecklistItemModel(
      id: id,
      title: json['title']?.toString() ?? '',
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      isChecked: json['isCompleted'] as bool? ?? false,
      memo: json['memo']?.toString(),
    );
  }
}
