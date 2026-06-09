import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';

class HomeSummary {
  final int userDisasterId;
  final String userName;
  final String disasterTitle;
  final String disasterTypeName;
  final String occurredAt;
  final String recoveryStageName;
  final double recoveryProgress;
  final bool dailyStatusChecked;
  final int todayTotalTasks;
  final int todayCompletedTasks;
  final double todayCompletionRate;

  HomeSummary({
    required this.userDisasterId,
    required this.userName,
    required this.disasterTitle,
    required this.disasterTypeName,
    required this.occurredAt,
    required this.recoveryStageName,
    required this.recoveryProgress,
    required this.dailyStatusChecked,
    required this.todayTotalTasks,
    required this.todayCompletedTasks,
    required this.todayCompletionRate,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    return HomeSummary(
      userDisasterId: (json['userDisasterId'] as num).toInt(),
      userName: json['userName']?.toString() ?? '',
      disasterTitle: json['disasterTitle']?.toString() ?? '',
      disasterTypeName: json['disasterTypeName']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
      recoveryStageName: json['recoveryStageName']?.toString() ?? '',
      recoveryProgress: (json['recoveryProgress'] as num?)?.toDouble() ?? 0.0,
      dailyStatusChecked: json['dailyStatusChecked'] as bool? ?? false,
      todayTotalTasks: (json['todayTotalTasks'] as num?)?.toInt() ?? 0,
      todayCompletedTasks: (json['todayCompletedTasks'] as num?)?.toInt() ?? 0,
      todayCompletionRate:
          (json['todayCompletionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyStatusCheckStatus {
  final bool checked;

  DailyStatusCheckStatus({required this.checked});

  factory DailyStatusCheckStatus.fromJson(Map<String, dynamic> json) {
    return DailyStatusCheckStatus(checked: json['checked'] as bool? ?? false);
  }
}

class TodayTaskItem {
  final int checklistItemId;
  final String title;
  final int priority;
  bool isCompleted;
  final bool isAiGenerated;

  TodayTaskItem({
    required this.checklistItemId,
    required this.title,
    required this.priority,
    required this.isCompleted,
    required this.isAiGenerated,
  });

  factory TodayTaskItem.fromJson(Map<String, dynamic> json) {
    return TodayTaskItem(
      checklistItemId: (json['checklistItemId'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
    );
  }
}

class TodayTasksResponse {
  final int totalCount;
  final List<TodayTaskItem> items;

  TodayTasksResponse({required this.totalCount, required this.items});

  factory TodayTasksResponse.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List<dynamic>?)
            ?.map(
              (e) =>
                  TodayTaskItem.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        [];
    return TodayTasksResponse(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
      items: items,
    );
  }
}

class RecoveryStageResponse {
  final int stageId;
  final String stageCode;
  final String stageName;
  final String description;

  RecoveryStageResponse({
    required this.stageId,
    required this.stageCode,
    required this.stageName,
    required this.description,
  });

  factory RecoveryStageResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryStageResponse(
      stageId: (json['stageId'] as num?)?.toInt() ?? 1,
      stageCode: json['stageCode']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class RecoveryStageInDisaster {
  final String stageCode;
  final String stageName;

  RecoveryStageInDisaster({required this.stageCode, required this.stageName});

  factory RecoveryStageInDisaster.fromJson(Map<String, dynamic> json) {
    return RecoveryStageInDisaster(
      stageCode: json['stageCode']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
    );
  }
}

class UserDisasterSummary {
  final int userDisasterId;
  final String title;
  final String disasterTypeCode;
  final String disasterTypeName;
  final String status;
  final String occurredAt;
  final String? endedAt;
  final RecoveryStageInDisaster? recoveryStage;
  final double recoveryProgress;

  UserDisasterSummary({
    required this.userDisasterId,
    required this.title,
    required this.disasterTypeCode,
    required this.disasterTypeName,
    required this.status,
    required this.occurredAt,
    this.endedAt,
    this.recoveryStage,
    required this.recoveryProgress,
  });

  factory UserDisasterSummary.fromJson(Map<String, dynamic> json) {
    return UserDisasterSummary(
      userDisasterId: (json['userDisasterId'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      disasterTypeCode: json['disasterTypeCode']?.toString() ?? '',
      disasterTypeName: json['disasterTypeName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
      endedAt: json['endedAt']?.toString(),
      recoveryStage: json['recoveryStage'] != null
          ? RecoveryStageInDisaster.fromJson(
              Map<String, dynamic>.from(json['recoveryStage'] as Map),
            )
          : null,
      recoveryProgress: (json['recoveryProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get displayLabel {
    final dateStr = _formatDate(occurredAt);
    return '$disasterTypeName 피해  |  $dateStr';
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y - $m - $d';
    } catch (_) {
      return iso;
    }
  }
}

class DisasterListResponse {
  final List<UserDisasterSummary> content;
  final int page;
  final int size;
  final int totalElements;

  DisasterListResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  factory DisasterListResponse.fromJson(Map<String, dynamic> json) {
    final content =
        (json['content'] as List<dynamic>?)
            ?.map(
              (e) => UserDisasterSummary.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        [];
    return DisasterListResponse(
      content: content,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeApi {
  final Dio _dio = AuthService().dio;

  Future<HomeSummary> getHomeSummary() async {
    if (kDebugMode) debugPrint('[홈] 요약 조회');
    final response = await _dio.get('/api/v1/home/summary');
    return HomeSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DailyStatusCheckStatus> getDailyStatus() async {
    if (kDebugMode) debugPrint('[홈] 오늘 상태 체크 조회');
    final response = await _dio.get('/api/v1/home/daily-status');
    return DailyStatusCheckStatus.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TodayTasksResponse> getTodayTasks() async {
    if (kDebugMode) debugPrint('[홈] 오늘 할 일 조회');
    final response = await _dio.get('/api/v1/home/today-tasks');
    return TodayTasksResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TodayTasksResponse> getTodayTasksFull() async {
    if (kDebugMode) debugPrint('[홈] 전체 할 일 조회');
    final response = await _dio.get('/api/v1/home/today-tasks/full');
    return TodayTasksResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RecoveryStageResponse> getRecoveryStage(int userDisasterId) async {
    if (kDebugMode) debugPrint('[홈] 회복 단계 조회: disasterId=$userDisasterId');
    final response = await _dio.get(
      '/api/v1/disasters/$userDisasterId/recovery/stage',
    );
    return RecoveryStageResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DisasterListResponse> getDisasterList() async {
    if (kDebugMode) debugPrint('[홈] 재난 목록 조회');
    final response = await _dio.get(
      '/api/v1/disasters',
      queryParameters: {'page': 0, 'size': 20},
    );
    return DisasterListResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> updateChecklistStatus({
    required int userDisasterId,
    required int checklistItemId,
    required bool isCompleted,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[홈] 완료 상태 변경: checklistItemId=$checklistItemId isCompleted=$isCompleted',
      );
    }
    await _dio.patch(
      '/api/v1/disasters/$userDisasterId/checklist/$checklistItemId/status',
      data: {'isCompleted': isCompleted},
    );
  }
}
