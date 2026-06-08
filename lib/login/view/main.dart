import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  void debugFirebaseTokenClaims(String token) {
    final parts = token.split('.');

    if (parts.length != 3) {
      debugPrint('[토큰 검사] JWT 형식 아님');
      return;
    }

    final payloadJson = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );

    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    debugPrint('[토큰 검사] iss=${payload['iss']}');
    debugPrint('[토큰 검사] aud=${payload['aud']}');
    debugPrint('[토큰 검사] iat=${payload['iat']}');
    debugPrint('[토큰 검사] exp=${payload['exp']}');
    debugPrint('[토큰 검사] now=$now');
    debugPrint('[토큰 검사] remaining=${(payload['exp'] as int) - now}');
  }

  /// Google → Firebase 인증 후 Firebase ID Token 반환
  Future<String> _getFirebaseToken() async {
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

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final String firebaseToken = await _getFirebaseToken();
      debugPrint('[토큰 검사] length=${firebaseToken.length}');
      debugPrint('[토큰 검사] dotCount=${'.'.allMatches(firebaseToken).length}');
      debugPrint('[토큰 검사] startsWith=${firebaseToken.substring(0, 10)}');
      debugFirebaseTokenClaims(firebaseToken);
      final LoginResult result = await _authService.loginWithFirebaseToken(
        firebaseToken,
      );

      if (!mounted) return;

      if (result == LoginResult.success) {
        // 기존 사용자: 홈으로 바로 이동 (온보딩 없음)
        Navigator.pushReplacementNamed(context, '/home');
      } else if (result == LoginResult.newUser) {
        // 신규 사용자: pending firebase token은 AuthService가 저장함
        // 온보딩에서 name/birthDate 수집 후 register 처리
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } on AuthException catch (e) {
      // 401: Firebase 토큰 오류 — 온보딩으로 이동하지 않음
      _showError(e.message);
    } on DioException catch (e) {
      _showError('네트워크 오류가 발생했습니다. 연결을 확인해 주세요. (${e.type.name})');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Firebase 로그인 중 오류가 발생했습니다.');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
