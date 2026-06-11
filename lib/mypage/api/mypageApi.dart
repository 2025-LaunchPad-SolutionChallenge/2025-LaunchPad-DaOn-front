import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/mypage/model/userModel.dart';

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

  // ──────────────────────────────────────────────────────────────
  // 프로필 조회
  // GET /api/v1/users/me
  // ──────────────────────────────────────────────────────────────
  Future<UserProfile> getUserProfile() async {
    const path = '/api/v1/users/me';

    if (kDebugMode) {
      final token = await _authService.getAccessToken();
      debugPrint('[프로필 조회] GET $path');
      debugPrint(
        '[프로필 조회] Authorization=${token != null && token.isNotEmpty ? '있음' : '없음'}',
      );
    }

    try {
      final response = await _authService.dio.get(path);

      if (kDebugMode) {
        debugPrint('[프로필 조회 응답] ${response.statusCode} | ${response.data}');
      }

      final data = response.data;
      if (data is! Map) throw Exception('프로필 응답 형식이 올바르지 않습니다.');

      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '프로필 조회에 실패했습니다.'));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 거주지 인증 상태 조회
  // GET /api/v1/auth/residence
  // 오류 시 null 반환 (페이지 크래시 방지)
  // ──────────────────────────────────────────────────────────────
  Future<ResidenceStatus?> getResidenceStatus() async {
    const path = '/api/v1/auth/residence';

    if (kDebugMode) {
      final token = await _authService.getAccessToken();
      debugPrint('[거주지 상태] GET $path');
      debugPrint(
        '[거주지 상태] Authorization=${token != null && token.isNotEmpty ? '있음' : '없음'}',
      );
    }

    try {
      final response = await _authService.dio.get(path);

      if (kDebugMode) {
        debugPrint('[거주지 상태 응답] ${response.statusCode} | ${response.data}');
      }

      final data = response.data;
      if (data is! Map) return null;

      return ResidenceStatus.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[거주지 상태 오류] ${e.response?.statusCode} | ${e.message} | ${e.response?.data}',
        );
      }
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 프로필 수정
  // PUT /api/v1/users/me (multipart/form-data)
  // 변경된 필드만 전송. 빈 문자열은 전송하지 않음.
  // ──────────────────────────────────────────────────────────────
  Future<MypageActionResponse> updateUserProfile({
    String? nickname,
    String? addressName,
    String? householdType,
    String? profileImageUrl,
  }) async {
    const path = '/api/v1/users/me';

    final fields = <String, dynamic>{};
    if (nickname != null && nickname.trim().isNotEmpty) {
      fields['nickname'] = nickname.trim();
    }
    if (addressName != null && addressName.trim().isNotEmpty) {
      fields['addressName'] = addressName.trim();
    }
    if (householdType != null) {
      fields['householdType'] = householdType;
    }
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      fields['profileImageUrl'] = profileImageUrl;
    }

    if (kDebugMode) {
      debugPrint('[프로필 수정] PUT $path');
      debugPrint('[프로필 수정] fields=$fields');
    }

    try {
      final response = await _authService.dio.put(
        path,
        data: FormData.fromMap(fields),
      );

      if (kDebugMode) {
        debugPrint('[프로필 수정 응답] ${response.statusCode} | ${response.data}');
      }

      return MypageActionResponse.fromResponseData(
        response.data,
        defaultMessage: '프로필이 수정되었습니다.',
      );
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '프로필 수정에 실패했습니다.'));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 프로필 이미지 URL 저장
  // POST /api/v1/users/me/profile-image
  // Firebase Storage 업로드 후 URL을 백엔드에 저장하는 용도
  // ──────────────────────────────────────────────────────────────
  Future<String> uploadProfileImageUrl(String profileImageUrl) async {
    const path = '/api/v1/users/me/profile-image';

    if (kDebugMode) {
      debugPrint('[프로필 이미지] POST $path');
      debugPrint('[프로필 이미지] url=$profileImageUrl');
    }

    try {
      final response = await _authService.dio.post(
        path,
        data: {'profileImageUrl': profileImageUrl},
      );

      if (kDebugMode) {
        debugPrint('[프로필 이미지 응답] ${response.statusCode} | ${response.data}');
      }

      final data = response.data;
      if (data is Map && data['profileImageUrl'] != null) {
        return data['profileImageUrl'].toString();
      }

      throw Exception('서버 응답에 profileImageUrl이 없습니다.');
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '프로필 이미지 저장에 실패했습니다.'));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 거주지 재인증
  // POST /api/v1/auth/residence/reverify
  // 409 BASELINE_NOT_FOUND, 429 VERIFY_COOLDOWN 처리 포함
  // ──────────────────────────────────────────────────────────────
  Future<ResidenceStatus> reverifyResidence({
    required double currentLatitude,
    required double currentLongitude,
    required String currentAddress,
  }) async {
    const path = '/api/v1/auth/residence/reverify';

    if (kDebugMode) {
      debugPrint('[거주지 재인증] POST $path');
      debugPrint(
        '[거주지 재인증] lat=$currentLatitude lng=$currentLongitude address=$currentAddress',
      );
    }

    try {
      final response = await _authService.dio.post(
        path,
        data: {
          'currentLatitude': currentLatitude,
          'currentLongitude': currentLongitude,
          'currentAddress': currentAddress,
        },
      );

      if (kDebugMode) {
        debugPrint('[거주지 재인증 응답] ${response.statusCode} | ${response.data}');
      }

      final data = response.data;
      if (data is! Map) throw Exception('거주지 재인증 응답 형식이 올바르지 않습니다.');

      return ResidenceStatus.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      final code = (data is Map) ? data['code']?.toString() : null;

      if (kDebugMode) {
        debugPrint('[거주지 재인증 오류] $status code=$code | ${e.message} | $data');
      }

      if (code == 'BASELINE_NOT_FOUND' || status == 409) {
        throw Exception('기존 거주지 인증 기준이 없습니다. 처음부터 인증을 진행해 주세요.');
      }

      if (code == 'VERIFY_COOLDOWN' || status == 429) {
        throw Exception('거주지 인증 재시도는 잠시 후 가능합니다. 쿨다운이 지난 뒤 다시 시도해 주세요.');
      }

      throw Exception(_extractDioErrorMessage(e, '거주지 재인증에 실패했습니다.'));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // 재난 상태 변경 (종료/보관)
  // PATCH /api/v1/disasters/{userDisasterId}/close
  // action: "CLOSE" → EXPIRED | "ARCHIVE" → ARCHIVED
  // ──────────────────────────────────────────────────────────────
  Future<void> closeDisaster({
    required int userDisasterId,
    required String action,
    String? endedAt,
  }) async {
    final path = '/api/v1/disasters/$userDisasterId/close';
    final data = <String, dynamic>{'action': action};
    if (endedAt != null) data['endedAt'] = endedAt;

    if (kDebugMode) debugPrint('[재난 상태 변경] PATCH $path action=$action endedAt=$endedAt');

    try {
      final response = await _authService.dio.patch(path, data: data);
      if (kDebugMode) debugPrint('[재난 상태 변경 응답] ${response.statusCode} | ${response.data}');
    } on DioException catch (e) {
      throw Exception(_extractDioErrorMessage(e, '재난 상태 변경에 실패했습니다.'));
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
