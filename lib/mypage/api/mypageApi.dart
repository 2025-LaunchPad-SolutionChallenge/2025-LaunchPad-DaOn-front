import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';

class MypageActionResponse {
  final String status;
  final String message;

  const MypageActionResponse({required this.status, required this.message});

  factory MypageActionResponse.fromJson(
    Map<String, dynamic> json, {
    String defaultMessage = '요청이 완료되었습니다.',
  }) {
    return MypageActionResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? defaultMessage,
    );
  }

  factory MypageActionResponse.fromResponseData(
    dynamic data, {
    required String defaultMessage,
  }) {
    if (data is Map) {
      return MypageActionResponse.fromJson(
        Map<String, dynamic>.from(data),
        defaultMessage: defaultMessage,
      );
    }

    if (data is String && data.isNotEmpty) {
      return MypageActionResponse(status: 'SUCCESS', message: data);
    }

    return MypageActionResponse(status: 'SUCCESS', message: defaultMessage);
  }
}

class MypageApi {
  final AuthService _authService;

  MypageApi({AuthService? authService})
    : _authService = authService ?? AuthService();

  // ──────────────────────────────────────────────────────────────
  // 로그아웃
  // POST /api/v1/auth/logout
  // accessToken: Dio interceptor에서 Authorization에 자동 포함된다고 가정
  // refreshToken: body로 전달
  // ──────────────────────────────────────────────────────────────
  Future<MypageActionResponse> logoutUser() async {
    const path = '/api/v1/auth/logout';

    final accessToken = await _authService.getAccessToken();
    final refreshToken = await _authService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('refreshToken이 없습니다. 다시 로그인해 주세요.');
    }

    if (kDebugMode) {
      debugPrint('[로그아웃] POST $path');
      debugPrint(
        '[로그아웃] Authorization=${accessToken != null && accessToken.isNotEmpty ? '있음' : '없음'}',
      );
      debugPrint(
        '[로그아웃] refreshToken=${refreshToken.isNotEmpty ? '있음' : '없음'}',
      );
    }

    try {
      final response = await _authService.dio.post(
        path,
        data: {'refreshToken': refreshToken},
      );

      if (kDebugMode) {
        debugPrint('[로그아웃 응답] ${response.statusCode} | ${response.data}');
      }

      return MypageActionResponse.fromResponseData(
        response.data,
        defaultMessage: '로그아웃되었습니다.',
      );
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '로그아웃 요청에 실패했습니다.'));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 회원 탈퇴
  // DELETE /api/v1/auth/withdraw
  // accessToken: Dio interceptor에서 Authorization에 자동 포함된다고 가정
  // ──────────────────────────────────────────────────────────────
  Future<MypageActionResponse> withdrawUser() async {
    const path = '/api/v1/auth/withdraw';

    final accessToken = await _authService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('accessToken이 없습니다. 다시 로그인해 주세요.');
    }

    if (kDebugMode) {
      debugPrint('[회원탈퇴] DELETE $path');
      debugPrint('[회원탈퇴] Authorization=있음');
    }

    try {
      final response = await _authService.dio.delete(path);

      if (kDebugMode) {
        debugPrint('[회원탈퇴 응답] ${response.statusCode} | ${response.data}');
      }

      return MypageActionResponse.fromResponseData(
        response.data,
        defaultMessage: '회원 탈퇴가 완료되었습니다.',
      );
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '회원 탈퇴 요청에 실패했습니다.'));
    }
  }

  String _extractDioErrorMessage(DioException e, String fallbackMessage) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;

    if (kDebugMode) {
      debugPrint('[MypageApi 오류] $status | ${e.message} | $data');
    }

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return '$fallbackMessage ($status)';
  }
}
