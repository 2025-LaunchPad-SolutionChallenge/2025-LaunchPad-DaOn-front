import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';

class DailyStatusResult {
  final int dailyCheckId;
  final int totalScore;
  final String message;

  DailyStatusResult({
    required this.dailyCheckId,
    required this.totalScore,
    required this.message,
  });

  factory DailyStatusResult.fromJson(Map<String, dynamic> json) {
    return DailyStatusResult(
      dailyCheckId: (json['dailyCheckId'] as num).toInt(),
      totalScore: (json['totalScore'] as num).toInt(),
      message: json['message']?.toString() ?? '',
    );
  }
}

class DailyStatusApi {
  final Dio _dio = AuthService().dio;

  Future<DailyStatusResult> submitDailyStatus({
    required int emotionScore,
    required int energyScore,
    required int activityScore,
    required int recoveryScore,
    required int needScore,
  }) async {
    final body = {
      'emotionScore': emotionScore,
      'energyScore': energyScore,
      'activityScore': activityScore,
      'recoveryScore': recoveryScore,
      'needScore': needScore,
    };

    if (kDebugMode) {
      debugPrint('[상태체크] POST /home/daily-status');
      debugPrint('[상태체크] 요청 본문: $body');
      debugPrint('[상태체크] Authorization: 인터셉터에서 Bearer 자동 첨부');
    }

    try {
      final response = await _dio.post('/api/v1/home/daily-status', data: body);

      if (kDebugMode) {
        debugPrint('[상태체크] 응답 상태: ${response.statusCode}');
        debugPrint('[상태체크] 응답 본문: ${response.data}');
      }

      return DailyStatusResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      if (kDebugMode) {
        debugPrint('[상태체크] 오류 상태: $status');
        debugPrint('[상태체크] 오류 본문: $data');
      }

      if (status == 409) {
        throw Exception('오늘은 이미 상태 체크를 완료했어요.');
      }

      String msg = '상태 체크 제출에 실패했습니다.';
      if (data is Map) {
        msg = data['message']?.toString() ?? msg;
      }
      throw Exception(msg);
    }
  }
}
