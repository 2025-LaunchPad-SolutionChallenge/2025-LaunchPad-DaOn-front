import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  static const String _expectedFirebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'daon-launchpad',
  );

  void _debugFirebaseTokenClaims(String token) {
    if (!kDebugMode) return;

    try {
      final parts = token.split('.');

      debugPrint('[토큰 검사] length=${token.length}');
      debugPrint('[토큰 검사] dotCount=${'.'.allMatches(token).length}');
      debugPrint('[토큰 검사] startsWith=${token.length >= 10 ? token.substring(0, 10) : token}');

      if (parts.length != 3) {
        debugPrint('[토큰 검사] JWT 형식 아님');
        return;
      }

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

      final iss = payload['iss']?.toString();
      final aud = payload['aud']?.toString();
      final exp = payload['exp'];
      final iat = payload['iat'];

      debugPrint('[토큰 검사] iss=$iss');
      debugPrint('[토큰 검사] aud=$aud');
      debugPrint('[토큰 검사] iat=$iat');
      debugPrint('[토큰 검사] exp=$exp');
      debugPrint('[토큰 검사] now=$now');

      if (exp is int) {
        debugPrint('[토큰 검사] remaining=${exp - now}');
      }

      if (aud != _expectedFirebaseProjectId ||
          iss != 'https://securetoken.google.com/$_expectedFirebaseProjectId') {
        debugPrint(
          '[토큰 검사] 경고: 프론트 Firebase project가 기대값과 다릅니다. '
          'expected=$_expectedFirebaseProjectId, aud=$aud, iss=$iss',
        );
      }
    } catch (e) {
      debugPrint('[토큰 검사] payload 디코딩 실패: $e');
    }
  }

  /// Google → Firebase 인증 후 Firebase ID Token 반환
  Future<String> _getFreshFirebaseToken() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception('Firebase 사용자 정보를 가져오지 못했습니다.');
    }

    // 서버에 보낼 토큰은 Google ID Token이 아니라 Firebase ID Token이어야 합니다.
    await user.reload();
    final User? refreshedUser = FirebaseAuth.instance.currentUser;
    final String? idToken = await refreshedUser?.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Firebase ID Token을 가져오지 못했습니다.');
    }

    return idToken;
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 새 로그인 시 이전 온보딩 임시 토큰이 흐름을 방해하지 않도록 정리합니다.
      await _authService.clearPendingFirebaseToken();

      final String firebaseToken = await _getFreshFirebaseToken();
      _debugFirebaseTokenClaims(firebaseToken);

      final LoginResult result = await _authService.loginWithFirebaseToken(
        firebaseToken,
      );

      if (!mounted) return;

      switch (result) {
        case LoginResult.success:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case LoginResult.newUser:
          Navigator.pushReplacementNamed(context, '/onboarding');
          break;
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } on DioException catch (e) {
      _showError(_dioErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Firebase 로그인 중 오류가 발생했습니다.');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dioErrorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['detail'];
      if (message != null) {
        return '로그인 실패${status != null ? ' ($status)' : ''}: $message';
      }
    }

    return '네트워크 오류가 발생했습니다. 연결을 확인해 주세요. (${e.type.name})';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
