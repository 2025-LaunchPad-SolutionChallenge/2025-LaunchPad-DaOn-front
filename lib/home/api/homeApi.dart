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

class DisasterLocation {
  final double? latitude;
  final double? longitude;
  final String? address;

  DisasterLocation({this.latitude, this.longitude, this.address});

  factory DisasterLocation.fromJson(Map<String, dynamic> json) {
    return DisasterLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address']?.toString(),
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
  final String? address;
  final RecoveryStageInDisaster? recoveryStage;
  final double recoveryProgress;
  final DisasterLocation? location;

  UserDisasterSummary({
    required this.userDisasterId,
    required this.title,
    required this.disasterTypeCode,
    required this.disasterTypeName,
    required this.status,
    required this.occurredAt,
    this.endedAt,
    this.address,
    this.recoveryStage,
    required this.recoveryProgress,
    this.location,
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
      address: json['address']?.toString(),
      recoveryStage: json['recoveryStage'] != null
          ? RecoveryStageInDisaster.fromJson(
              Map<String, dynamic>.from(json['recoveryStage'] as Map),
            )
          : null,
      recoveryProgress: (json['recoveryProgress'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] != null
          ? DisasterLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map),
            )
          : null,
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

const Map<String, String> _stageDescriptions = {
  'CHAOS': '재난 직후 혼란스러운 상태입니다. 한 걸음씩 나아가세요.',
  'STAGNANT': '회복이 멈춘 것 같지만, 쉬어가는 것도 회복입니다.',
  'ATTEMPTING': '회복을 위한 시도를 시작했습니다. 잘 하고 있어요!',
  'STABLE': '일상이 안정되어 가고 있습니다. 계속 유지해 나가세요.',
  'RECOVERY_MAINTAINED': '꾸준한 회복을 유지하고 있습니다. 대단해요!',
};

class RecoveryProgress {
  final int userDisasterId;
  final double recoveryScore;
  final String stageCode;
  final String stageName;
  final String? description;

  RecoveryProgress({
    required this.userDisasterId,
    required this.recoveryScore,
    required this.stageCode,
    required this.stageName,
    this.description,
  });

  factory RecoveryProgress.fromJson(Map<String, dynamic> json) {
    final code = json['stageCode']?.toString() ?? '';
    final apiDesc = json['description']?.toString();
    return RecoveryProgress(
      userDisasterId: (json['userDisasterId'] as num?)?.toInt() ?? 0,
      recoveryScore: (json['recoveryScore'] as num?)?.toDouble() ?? 0.0,
      stageCode: code,
      stageName: json['stageName']?.toString() ?? '',
      description: (apiDesc != null && apiDesc.isNotEmpty)
          ? apiDesc
          : _stageDescriptions[code],
    );
  }

  int get stageId {
    const map = {
      'CHAOS': 1,
      'STAGNANT': 2,
      'ATTEMPTING': 3,
      'STABLE': 4,
      'RECOVERY_MAINTAINED': 5,
    };
    return map[stageCode] ?? 1;
  }
}

class WeeklyChecklistProgress {
  final String weekStart;
  final String weekEnd;
  final double completionRate;

  WeeklyChecklistProgress({
    required this.weekStart,
    required this.weekEnd,
    required this.completionRate,
  });

  factory WeeklyChecklistProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['completionRate'];
    double rate = 0.0;
    if (raw is num) {
      rate = raw.toDouble();
    } else if (raw is String) {
      rate = double.tryParse(raw.replaceAll('%', '').trim()) ?? 0.0;
    }
    return WeeklyChecklistProgress(
      weekStart: json['weekStart']?.toString() ?? '',
      weekEnd: json['weekEnd']?.toString() ?? '',
      completionRate: rate.clamp(0.0, 100.0),
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
    if (kDebugMode) debugPrint('[홈] GET /api/v1/disasters?page=0&size=20');
    final response = await _dio.get(
      '/api/v1/disasters',
      queryParameters: {'page': 0, 'size': 20},
    );
    if (kDebugMode) {
      debugPrint('[홈 재난 목록 응답] ${response.statusCode} | ${response.data}');
    }
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

  Future<RecoveryProgress> fetchRecoveryProgress(int disasterId) async {
    if (kDebugMode) {
      debugPrint('[회복] GET /api/v1/disasters/$disasterId/recovery/progress');
    }
    final response = await _dio.get(
      '/api/v1/disasters/$disasterId/recovery/progress',
    );
    if (kDebugMode) {
      debugPrint('[회복 응답] ${response.statusCode} | ${response.data}');
    }
    return RecoveryProgress.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// 개발/데모용: 회복 라벨링 배치를 즉시 실행합니다.
  /// kDebugMode에서만 동작하며, 실패해도 앱 흐름에 영향을 주지 않습니다.
  Future<void> runRecoveryBatch() async {
    if (!kDebugMode) return;
    try {
      debugPrint('[배치] POST /api/v1/dev/batch/recovery');
      final response = await _dio.post('/api/v1/dev/batch/recovery');
      debugPrint('[배치] 응답: ${response.statusCode} | ${response.data}');
    } catch (e) {
      debugPrint('[배치] 실패 (무시): $e');
    }
  }

  Future<WeeklyChecklistProgress> fetchWeeklyChecklistProgress(
    DateTime date,
  ) async {
    final y = date.year.toString();
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final dateStr = '$y-$mo-$d';
    if (kDebugMode) {
      debugPrint(
        '[체크리스트 주간] GET /api/v1/checklists/weekly-progress?date=$dateStr',
      );
    }
    final response = await _dio.get(
      '/api/v1/checklists/weekly-progress',
      queryParameters: {'date': dateStr},
    );
    if (kDebugMode) {
      debugPrint('[체크리스트 주간 응답] ${response.statusCode} | ${response.data}');
    }
    return WeeklyChecklistProgress.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
