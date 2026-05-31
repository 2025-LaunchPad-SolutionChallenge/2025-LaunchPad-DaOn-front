import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isLoadingTokens = false;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> _printWithdrawTestTokens() async {
    if (_isLoadingTokens) return;

    setState(() {
      _isLoadingTokens = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase 로그인 상태가 아닙니다.');
      }

      final String? accessToken = await _storage.read(key: 'access_token');
      final String? refreshToken = await _storage.read(key: 'refresh_token');
      final String? firebaseToken = await user.getIdToken(true);

      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception('Firebase 재인증 토큰을 가져오지 못했습니다.');
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print('[WITHDRAW TEST] accessToken=$accessToken');
        // ignore: avoid_print
        print('[WITHDRAW TEST] refreshToken=$refreshToken');
        // ignore: avoid_print
        print('[WITHDRAW TEST] firebaseToken=$firebaseToken');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('터미널에 withdraw 테스트 토큰을 출력했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTokens = false;
        });
      }
    }
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Expanded(
                  child: Center(child: Text('My Page')),
                ),
                if (kDebugMode)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorStyles.white,
                        foregroundColor: ColorStyles.main2,
                        disabledBackgroundColor:
                            ColorStyles.white.withValues(alpha: 0.7),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      onPressed:
                          _isLoadingTokens ? null : _printWithdrawTestTokens,
                      child: _isLoadingTokens
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorStyles.main2,
                              ),
                            )
                          : Text(
                              'Withdraw 테스트 토큰 출력',
                              style: FontStyles.semi16,
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
