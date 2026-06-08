import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum LoginResult { success, newUser }

class AuthException implements Exception {
  final int status;
  final String message;
  const AuthException({required this.status, required this.message});
  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _authDio = _buildAuthDio();
    dio = _buildAppDio();
  }

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// main.dart의 MaterialApp에 연결해야 refresh 실패 시 /login으로 이동 가능
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  /// 인증 전용 Dio: /login, /register, /refresh 전용
  /// Authorization 헤더 없음, validateStatus < 500 (4xx 응답을 수동으로 처리)
  late final Dio _authDio;

  /// 앱 API 전용 Dio: 인증된 요청에 사용
  /// Authorization 자동 첨부, 401 시 refresh → 재시도
  late final Dio dio;

  // ─── Dio 빌더 ────────────────────────────────────────────────────

  Dio _buildAuthDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        // 4xx를 예외로 던지지 않고 수동 처리
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (kDebugMode) d.interceptors.add(_debugInterceptor('인증'));
    return d;
  }

  Dio _buildAppDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        // 기본 validateStatus: 2xx만 성공으로 처리 → 401이 onError로 진입
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              await _performRefresh();
              final newToken = await _storage.read(key: 'access_token');
              final response =
                  await _retryRequest(error.requestOptions, newToken);
              handler.resolve(response);
              return;
            } catch (_) {
              // refresh 실패: 토큰 삭제 후 로그인 화면으로 이동
              await clearTokens();
              navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil('/login', (_) => false);
            } finally {
              _isRefreshing = false;
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) d.interceptors.add(_debugInterceptor('앱'));
    return d;
  }

  // ─── 공개 메서드 ─────────────────────────────────────────────────

  /// Firebase ID 토큰으로 로그인 시도
  /// 200 → LoginResult.success (토큰 저장)
  /// 404 → LoginResult.newUser (pending firebase token 저장)
  /// 401 → AuthException 던짐 (온보딩으로 이동하지 않음)
  Future<LoginResult> loginWithFirebaseToken(String firebaseToken) async {
    if (kDebugMode) {
      debugPrint('[인증] POST /api/v1/auth/login | firebaseToken=${_mask(firebaseToken)}');
    }

    final response = await _authDio.post(
      '/api/v1/auth/login',
      data: {'firebaseToken': firebaseToken},
    );
    final status = response.statusCode ?? 0;

    if (kDebugMode) debugPrint('[인증] 로그인 응답: $status');

    if (status == 200) {
      await _saveTokensFromResponse(_toMap(response.data));
      await clearPendingFirebaseToken();
      return LoginResult.success;
    }

    if (status == 404) {
      // 미가입 사용자: firebase 토큰을 임시 보관, 온보딩에서 register 처리
      await savePendingFirebaseToken(firebaseToken);
      return LoginResult.newUser;
    }

    if (status == 401) {
      throw AuthException(
        status: 401,
        message: 'Firebase 토큰 인증에 실패했습니다. 다시 로그인해 주세요.',
      );
    }

    throw AuthException(
      status: status,
      message: _errorMessage(response.data, '로그인 실패 ($status)'),
    );
  }

  /// 온보딩 데이터로 회원가입
  /// 성공 시 서버 토큰 저장, pending firebase token 삭제
  Future<void> registerWithOnboardingData({
    required String firebaseToken,
    required String name,
    required String birthDate,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[인증] POST /api/v1/auth/register | firebaseToken=${_mask(firebaseToken)} name=$name birthDate=$birthDate',
      );
    }

    final response = await _authDio.post(
      '/api/v1/auth/register',
      data: {
        'firebaseToken': firebaseToken,
        'name': name,
        'birthDate': birthDate,
      },
    );
    final status = response.statusCode ?? 0;

    if (kDebugMode) debugPrint('[인증] 회원가입 응답: $status');

    if (status == 200) {
      await _saveTokensFromResponse(_toMap(response.data));
      await clearPendingFirebaseToken();
      return;
    }

    if (status == 409) {
      throw AuthException(status: 409, message: '이미 가입된 계정입니다.');
    }

    if (status == 401) {
      throw AuthException(
        status: 401,
        message: '회원가입 실패: Firebase 토큰이 유효하지 않습니다.',
      );
    }

    throw AuthException(
      status: status,
      message: _errorMessage(response.data, '회원가입 실패 ($status)'),
    );
  }

  /// 외부에서 수동으로 토큰 갱신이 필요한 경우 호출
  Future<void> refreshTokens() => _performRefresh();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String tokenType = 'bearer',
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'token_type', value: tokenType);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_type');
  }

  Future<void> savePendingFirebaseToken(String token) async {
    await _storage.write(key: 'pending_firebase_token', value: token);
  }

  Future<String?> getPendingFirebaseToken() async {
    return _storage.read(key: 'pending_firebase_token');
  }

  Future<void> clearPendingFirebaseToken() async {
    await _storage.delete(key: 'pending_firebase_token');
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────────────

  Future<void> _performRefresh() async {
    final storedRefreshToken = await _storage.read(key: 'refresh_token');
    if (storedRefreshToken == null) {
      throw Exception('저장된 refresh token이 없습니다.');
    }

    if (kDebugMode) {
      debugPrint('[인증] POST /api/v1/auth/refresh | refreshToken=${_mask(storedRefreshToken)}');
    }

    // refresh는 별도 Dio 인스턴스 사용 (인터셉터 루프 방지)
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    final response = await refreshDio.post(
      '/api/v1/auth/refresh',
      data: {'refreshToken': storedRefreshToken},
    );

    if ((response.statusCode ?? 0) != 200) {
      throw Exception('토큰 갱신 실패 (${response.statusCode})');
    }

    await _saveTokensFromResponse(_toMap(response.data));
    if (kDebugMode) debugPrint('[인증] 토큰 갱신 완료');
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions options,
    String? token,
  ) {
    final retryDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    return retryDio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    final accessToken =
        (data['accessToken'] ?? data['access_token']) as String?;
    final refreshToken =
        (data['refreshToken'] ?? data['refresh_token']) as String?;
    if (accessToken == null || refreshToken == null) {
      throw Exception('서버 응답에 토큰이 없습니다.');
    }
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    if (kDebugMode) {
      debugPrint('[인증] 토큰 저장 완료: accessToken=${_mask(accessToken)}');
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('서버 응답 형식이 올바르지 않습니다.');
  }

  String _errorMessage(dynamic data, String fallback) {
    if (data is Map) {
      return data['detail']?.toString() ??
          data['message']?.toString() ??
          fallback;
    }
    return fallback;
  }

  /// JWT / Firebase 토큰 마스킹: eyJ...last4
  String _mask(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 3)}...${token.substring(token.length - 4)}';
  }

  Interceptor _debugInterceptor(String tag) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final body = options.data;
        String bodyLog = '';
        if (body is Map) {
          try {
            final masked = Map<String, dynamic>.from(body).map((k, v) {
              if (v is String &&
                  (v.startsWith('eyJ') ||
                      k.toLowerCase().contains('token'))) {
                return MapEntry(k, _mask(v));
              }
              return MapEntry(k, v);
            });
            bodyLog = masked.toString();
          } catch (_) {
            bodyLog = body.toString();
          }
        }
        debugPrint('[$tag 요청] ${options.method} ${options.path}');
        if (bodyLog.isNotEmpty) debugPrint('[$tag 요청 본문] $bodyLog');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '[$tag 응답] ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode}',
        );
        final dataStr = response.data?.toString() ?? '';
        debugPrint(
          '[$tag 응답 본문] ${dataStr.length > 300 ? '${dataStr.substring(0, 300)}...' : dataStr}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint(
          '[$tag 오류] ${error.requestOptions.method} ${error.requestOptions.path} → ${error.response?.statusCode} | ${error.message}',
        );
        if (error.response?.data != null) {
          debugPrint('[$tag 오류 본문] ${error.response?.data}');
        }
        handler.next(error);
      },
    );
  }
}
