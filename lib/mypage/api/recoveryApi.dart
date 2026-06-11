import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';

class RecoveryGraphPoint {
  final String date;
  final double recoveryScore;
  final String stageCode;
  final String stageName;

  RecoveryGraphPoint({
    required this.date,
    required this.recoveryScore,
    required this.stageCode,
    required this.stageName,
  });

  factory RecoveryGraphPoint.fromJson(Map<String, dynamic> json) {
    return RecoveryGraphPoint(
      date: json['date']?.toString() ?? '',
      recoveryScore: (json['recoveryScore'] as num?)?.toDouble() ?? 0.0,
      stageCode: json['stageCode']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
    );
  }
}

class RecoveryGraphResponse {
  final int userDisasterId;
  final List<RecoveryGraphPoint> points;

  RecoveryGraphResponse({required this.userDisasterId, required this.points});

  factory RecoveryGraphResponse.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>?) ?? [];
    return RecoveryGraphResponse(
      userDisasterId: (json['userDisasterId'] as num?)?.toInt() ?? 0,
      points: rawPoints
          .map(
            (e) => RecoveryGraphPoint.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class TimelineChecklistItem {
  final int checklistItemId;
  final String title;
  final bool isCompleted;
  final int priority;

  TimelineChecklistItem({
    required this.checklistItemId,
    required this.title,
    required this.isCompleted,
    required this.priority,
  });

  factory TimelineChecklistItem.fromJson(Map<String, dynamic> json) {
    return TimelineChecklistItem(
      checklistItemId: (json['checklistItemId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 2,
    );
  }
}

class TimelineChecklistDay {
  final String checklistDate;
  final int total;
  final int completed;
  final List<TimelineChecklistItem> items;

  TimelineChecklistDay({
    required this.checklistDate,
    required this.total,
    required this.completed,
    required this.items,
  });

  factory TimelineChecklistDay.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    return TimelineChecklistDay(
      checklistDate: json['checklistDate']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map(
            (e) => TimelineChecklistItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class TimelineChecklistResponse {
  final int userDisasterId;
  final List<TimelineChecklistDay> days;

  TimelineChecklistResponse({required this.userDisasterId, required this.days});

  factory TimelineChecklistResponse.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>?) ?? [];
    final days = rawDays
        .map(
          (e) => TimelineChecklistDay.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((d) => d.items.isNotEmpty)
        .toList();
    return TimelineChecklistResponse(
      userDisasterId: (json['userDisasterId'] as num?)?.toInt() ?? 0,
      days: days,
    );
  }
}

class RecoveryApi {
  final Dio _dio = AuthService().dio;

  Future<RecoveryGraphResponse> fetchRecoveryGraph(int userDisasterId) async {
    final path = '/api/v1/disasters/$userDisasterId/recovery-graph';
    if (kDebugMode) {
      debugPrint('[회복그래프] GET $path');
      debugPrint('[회복그래프] Authorization: 인터셉터에서 자동 첨부');
    }
    final response = await _dio.get(path);
    if (kDebugMode) {
      debugPrint('[회복그래프] 응답 status=${response.statusCode}');
      debugPrint('[회복그래프] 응답 body=${response.data}');
    }
    return RecoveryGraphResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TimelineChecklistResponse> fetchTimelineChecklist(
    int userDisasterId, {
    required String startDate,
    required String endDate,
  }) async {
    final path = '/api/v1/disasters/$userDisasterId/checklist';
    if (kDebugMode) {
      debugPrint('[타임라인] GET $path');
      debugPrint('[타임라인] query: startDate=$startDate endDate=$endDate');
      debugPrint('[타임라인] Authorization: 인터셉터에서 자동 첨부');
    }
    final response = await _dio.get(
      path,
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    if (kDebugMode) {
      debugPrint('[타임라인] 응답 status=${response.statusCode}');
      debugPrint('[타임라인] 응답 body=${response.data}');
    }
    return TimelineChecklistResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
