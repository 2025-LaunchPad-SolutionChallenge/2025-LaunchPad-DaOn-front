import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  /// Android Emulator에서 FastAPI 로컬 서버를 테스트할 때는 10.0.2.2 사용
  ///
  /// 실행 예시:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  ///
  /// 실제 기기 테스트 시:
  /// flutter run --dart-define=API_BASE_URL=http://내_PC_IP:8000

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 1. Google 로그인 → Firebase 로그인 → Firebase ID Token 발급
  Future<String> _signInWithGoogleAndGetFirebaseIdToken() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final String? idToken = await userCredential.user?.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Firebase ID Token을 가져오지 못했습니다.');
    }

    return idToken;
  }

  /// 2. FastAPI /auth/firebase로 Firebase ID Token 전송
  Future<BackendLoginResult> _loginToBackend(String idToken) async {
    final Response response = await _dio.post(
      '/api/v1/auth/login',
      data: {'firebaseToken': idToken},
    );
    return _parseAndPersistLoginResponse(response, fallbackErrorPrefix: '로그인 실패');
  }

  Future<BackendLoginResult> _registerToBackend(String idToken) async {
    final Response response = await _dio.post(
      '/api/v1/auth/register',
      data: {'firebaseToken': idToken},
    );
    return _parseAndPersistLoginResponse(response, fallbackErrorPrefix: '회원가입 실패');
  }

  Future<BackendLoginResult> _parseAndPersistLoginResponse(
    Response response, {
    required String fallbackErrorPrefix,
  }) async {
    if (response.statusCode != 200) {
      throw Exception(
        _extractServerErrorMessage(
          response,
          fallbackErrorPrefix: fallbackErrorPrefix,
        ),
      );
    }

    final Map<String, dynamic> data = _convertToMap(response.data);
    final BackendLoginResult result = BackendLoginResult.fromJson(data);

    await _storage.write(key: 'access_token', value: result.accessToken);
    await _storage.write(key: 'refresh_token', value: result.refreshToken);
    await _storage.write(key: 'token_type', value: result.tokenType);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AUTH] accessToken=${result.accessToken}');
      // ignore: avoid_print
      print('[AUTH] refreshToken=${result.refreshToken}');
    }

    return result;
  }

  /// 3. 로그인 버튼 클릭 시 실행되는 전체 흐름
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String firebaseIdToken =
          await _signInWithGoogleAndGetFirebaseIdToken();

      if (kDebugMode) {
        // ignore: avoid_print
        print('[AUTH] firebaseToken=$firebaseIdToken');
      }

      try {
        await _loginToBackend(firebaseIdToken);
      } on Exception catch (e) {
        final String error = e.toString();
        if (!error.contains('(404)')) {
          rethrow;
        }
        await _registerToBackend(firebaseIdToken);
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      _showErrorSnackBar(_extractDioErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Firebase 로그인 중 오류가 발생했습니다.');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('서버 응답 형식이 올바르지 않습니다.');
  }

  String _extractServerErrorMessage(
    Response response, {
    String fallbackErrorPrefix = '로그인 실패',
  }) {
    final dynamic data = response.data;

    if (data is Map && data['detail'] != null) {
      return '$fallbackErrorPrefix (${response.statusCode}): ${data['detail']}';
    }

    if (data is Map && data['message'] != null) {
      return '$fallbackErrorPrefix (${response.statusCode}): ${data['message']}';
    }

    return '$fallbackErrorPrefix (${response.statusCode}): 서버에서 토큰을 받아오지 못했습니다.';
  }

  String _extractDioErrorMessage(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final dynamic data = e.response?.data;

    if (data is Map && data['detail'] != null) {
      return '로그인 실패${statusCode != null ? ' ($statusCode)' : ''}: ${data['detail']}';
    }

    if (data is Map && data['message'] != null) {
      return '로그인 실패${statusCode != null ? ' ($statusCode)' : ''}: ${data['message']}';
    }

    return '로그인 실패${statusCode != null ? ' ($statusCode)' : ''}: ${e.message ?? '네트워크 오류가 발생했습니다.'}';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: HomeAppBarWidget(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.00),
            end: Alignment(1.00, 0.71),
            colors: [ColorStyles.main2, ColorStyles.main3],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorStyles.white,
                              foregroundColor: ColorStyles.main2,
                              disabledBackgroundColor: ColorStyles.white
                                  .withValues(alpha: 0.7),
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorStyles.main2,
                                    ),
                                  )
                                : Text(
                                    'Google 계정으로 로그인',
                                    style: FontStyles.semi16,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BackendLoginResult {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final bool isNewUser;

  const BackendLoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.isNewUser,
  });

  factory BackendLoginResult.fromJson(Map<String, dynamic> json) {
    final String? accessToken =
        (json['accessToken'] ?? json['access_token']) as String?;
    final String? refreshToken =
        (json['refreshToken'] ?? json['refresh_token']) as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('서버 응답에 access_token이 없습니다.');
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('서버 응답에 refresh_token이 없습니다.');
    }

    return BackendLoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: (json['tokenType'] ?? json['token_type']) as String? ?? 'bearer',
      isNewUser: (json['isNewUser'] ?? json['is_new_user']) as bool? ?? false,
    );
  }
}
