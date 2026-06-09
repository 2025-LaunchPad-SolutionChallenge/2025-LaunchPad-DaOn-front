import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum LoginResult { success, newUser }

class AuthException implements Exception {
  final int status;
  final String code;
  final String message;

  const AuthException({
    required this.status,
    required this.message,
    this.code = '',
  });

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

  /// MaterialApp에 연결하면 refresh 실패 시 어디서든 /login으로 이동할 수 있습니다.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  /// 인증 전용 Dio: /login, /register, /refresh 전용
  /// Authorization 헤더를 절대 붙이지 않습니다.
  late final Dio _authDio;

  /// 앱 API 전용 Dio: 인증된 요청에 사용
  /// Authorization 자동 첨부, 401 시 refresh 후 1회 재시도합니다.
  late final Dio dio;

  Dio _buildAuthDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
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
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 실수로 app dio로 auth endpoint를 호출해도 Bearer가 붙지 않게 방어합니다.
          if (_isAuthEndpoint(options.path)) {
            options.headers.remove('Authorization');
            return handler.next(options);
          }

          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (status == 401 &&
              !_isAuthEndpoint(path) &&
              !_isRefreshing &&
              !alreadyRetried) {
            _isRefreshing = true;

            try {
              await _performRefresh();
              final newToken = await _storage.read(key: 'access_token');
              final response = await _retryRequest(
                error.requestOptions,
                newToken,
              );
              handler.resolve(response);
              return;
            } catch (_) {
              await clearTokens();
              await clearPendingFirebaseToken();
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/login',
                (_) => false,
              );
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

  /// Firebase ID Token으로 백엔드 로그인을 시도합니다.
  /// 200: 기존 사용자 → 서버 토큰 저장
  /// 404 USER_NOT_FOUND: 신규 사용자 → pending firebase token 저장 후 온보딩으로 이동해야 함
  /// 401 INVALID_FIREBASE_TOKEN: Firebase 토큰 검증 실패 → 온보딩으로 이동하면 안 됨
  Future<LoginResult> loginWithFirebaseToken(String firebaseToken) async {
    if (kDebugMode) {
      debugPrint(
        '[인증] POST /api/v1/auth/login | firebaseToken=${_mask(firebaseToken)}',
      );
    }

    final response = await _authDio.post(
      '/api/v1/auth/login',
      data: {'firebaseToken': firebaseToken},
    );

    final status = response.statusCode ?? 0;
    final body = _safeMap(response.data);
    final code = body['code']?.toString() ?? '';
    final message = _errorMessage(response.data, '로그인 실패 ($status)');

    if (kDebugMode) debugPrint('[인증] 로그인 응답: $status code=$code');

    if (_isSuccess(status)) {
      await _saveTokensFromResponse(_toMap(response.data));
      await clearPendingFirebaseToken();
      return LoginResult.success;
    }

    if (status == 404 || code == 'USER_NOT_FOUND') {
      await clearTokens();
      await savePendingFirebaseToken(firebaseToken);
      return LoginResult.newUser;
    }

    if (status == 401 || code == 'INVALID_FIREBASE_TOKEN') {
      throw AuthException(
        status: status,
        code: code,
        message:
            '$message\n백엔드 Firebase Admin SDK의 project_id/service account가 프론트 Firebase 프로젝트와 같은지 확인해 주세요.',
      );
    }

    throw AuthException(status: status, code: code, message: message);
  }

  /// 온보딩 Step 1 완료 후 회원가입합니다.
  /// 성공 시 서버 accessToken/refreshToken을 저장하고 pending firebase token을 삭제합니다.
  Future<void> registerWithOnboardingData({
    required String firebaseToken,
    required String name,
    required String birthDate,
  }) async {
    final trimmedName = name.trim();
    final normalizedBirthDate = birthDate.trim().replaceAll('.', '-');

    if (trimmedName.isEmpty) {
      throw const AuthException(status: 400, message: '이름을 입력해 주세요.');
    }

    if (trimmedName.length > 6) {
      throw const AuthException(status: 400, message: '이름은 6글자 이하로 입력해 주세요.');
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalizedBirthDate)) {
      throw const AuthException(
        status: 400,
        message: '생년월일은 YYYY-MM-DD 형식이어야 합니다.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[인증] POST /api/v1/auth/register | firebaseToken=${_mask(firebaseToken)} name=$trimmedName birthDate=$normalizedBirthDate',
      );
    }

    final response = await _authDio.post(
      '/api/v1/auth/register',
      data: {
        'firebaseToken': firebaseToken,
        'name': trimmedName,
        'birthDate': normalizedBirthDate,
      },
    );

    final status = response.statusCode ?? 0;
    final body = _safeMap(response.data);
    final code = body['code']?.toString() ?? '';

    if (kDebugMode) debugPrint('[인증] 회원가입 응답: $status code=$code');

    if (_isSuccess(status)) {
      await _saveTokensFromResponse(_toMap(response.data));
      await clearPendingFirebaseToken();
      return;
    }

    if (status == 409 || code == 'DUPLICATE_FIREBASE_USER') {
      throw const AuthException(
        status: 409,
        code: 'DUPLICATE_FIREBASE_USER',
        message: '이미 가입된 계정입니다. 다시 로그인해 주세요.',
      );
    }

    throw AuthException(
      status: status,
      code: code,
      message: _errorMessage(response.data, '회원가입 실패 ($status)'),
    );
  }

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

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> savePendingFirebaseToken(String token) async {
    await _storage.write(key: 'pending_firebase_token', value: token);
  }

  Future<String?> getPendingFirebaseToken() {
    return _storage.read(key: 'pending_firebase_token');
  }

  Future<void> clearPendingFirebaseToken() async {
    await _storage.delete(key: 'pending_firebase_token');
  }

  /// 디버그 중 저장된 인증 상태를 완전히 초기화할 때 사용합니다.
  Future<void> clearAuthState() async {
    await clearTokens();
    await clearPendingFirebaseToken();
  }

  Future<void> _performRefresh() async {
    final storedRefreshToken = await _storage.read(key: 'refresh_token');
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      throw Exception('저장된 refresh token이 없습니다.');
    }

    if (kDebugMode) {
      debugPrint(
        '[인증] POST /api/v1/auth/refresh | refreshToken=${_mask(storedRefreshToken)}',
      );
    }

    final response = await _authDio.post(
      '/api/v1/auth/refresh',
      data: {'refreshToken': storedRefreshToken},
    );

    final status = response.statusCode ?? 0;

    if (!_isSuccess(status)) {
      throw Exception(_errorMessage(response.data, '토큰 갱신 실패 ($status)'));
    }

    await _saveTokensFromResponse(_toMap(response.data));
    if (kDebugMode) debugPrint('[인증] 토큰 갱신 완료');
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions options,
    String? token,
  ) {
    final headers = Map<String, dynamic>.from(options.headers);
    headers.remove('Authorization');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

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
        headers: headers,
        extra: {...options.extra, 'retried': true},
      ),
    );
  }

  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    final accessToken =
        (data['accessToken'] ?? data['access_token']) as String?;
    final refreshToken =
        (data['refreshToken'] ?? data['refresh_token']) as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('서버 응답에 accessToken이 없습니다.');
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('서버 응답에 refreshToken이 없습니다.');
    }

    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    if (kDebugMode) {
      debugPrint('[DEBUG] accessToken=$accessToken');
      debugPrint('[DEBUG] refreshToken=$refreshToken');
    }

    if (kDebugMode) {
      debugPrint('[인증] 토큰 저장 완료: accessToken=${_mask(accessToken)}');
    }
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/register') ||
        path.contains('/api/v1/auth/refresh');
  }

  bool _isSuccess(int status) => status >= 200 && status < 300;

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('서버 응답 형식이 올바르지 않습니다.');
  }

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _errorMessage(dynamic data, String fallback) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['detail']?.toString() ??
          fallback;
    }
    return fallback;
  }

  String _mask(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 3)}...${token.substring(token.length - 4)}';
  }

  dynamic _maskTokenValues(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic v) {
        final k = key.toString().toLowerCase();
        if (v is String && (v.startsWith('eyJ') || k.contains('token'))) {
          return MapEntry(key, _mask(v));
        }
        return MapEntry(key, _maskTokenValues(v));
      });
    }

    if (value is List) {
      return value.map(_maskTokenValues).toList();
    }

    return value;
  }

  Interceptor _debugInterceptor(String tag) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[$tag 요청] ${options.method} ${options.path}');

        final hasAuth =
            options.headers.containsKey('Authorization') &&
            options.headers['Authorization'] != null;
        debugPrint('[$tag 요청 헤더] Authorization=${hasAuth ? '있음' : '없음'}');

        if (options.data != null) {
          debugPrint('[$tag 요청 본문] ${_maskTokenValues(options.data)}');
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '[$tag 응답] ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode}',
        );

        final dataStr = _maskTokenValues(response.data).toString();
        debugPrint(
          '[$tag 응답 본문] ${dataStr.length > 500 ? '${dataStr.substring(0, 500)}...' : dataStr}',
        );

        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint(
          '[$tag 오류] ${error.requestOptions.method} ${error.requestOptions.path} → ${error.response?.statusCode} | ${error.message}',
        );

        if (error.response?.data != null) {
          debugPrint('[$tag 오류 본문] ${_maskTokenValues(error.response?.data)}');
        }

        handler.next(error);
      },
    );
  }
}
