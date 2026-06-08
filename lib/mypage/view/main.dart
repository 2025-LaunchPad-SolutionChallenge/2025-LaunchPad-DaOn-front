import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/mypage/widget/myPageAppBarWidget.dart';
import 'package:project_daon/mypage/widget/myProfileWidget.dart';
import 'package:project_daon/mypage/widget/recoverydashboardWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String name = '이재현';
  int level = 2;
  String disaster = '홍수';

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
      appBar: MypageAppBarWidget(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 100.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorStyles.main2, ColorStyles.main3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              MyProfileWidget(name: name, level: level, disaster: disaster),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                width: double.infinity,
                child: ChecklistProgessBar(currentCheck: 58.9),
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 30.0,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: const ShapeDecoration(
                    color: ColorStyles.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(17),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecoveryDashboardWidget(),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '내 식물 확인하기',
                          style: FontStyles.med16.copyWith(
                            color: ColorStyles.black2,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '로그아웃',
                          style: FontStyles.med16.copyWith(
                            color: ColorStyles.black2,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '회원 탈퇴',
                          style: FontStyles.med16.copyWith(
                            color: ColorStyles.black2,
                          ),
                        ),
                      ),

                      if (kDebugMode) ...[
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
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
                                side: const BorderSide(
                                  color: ColorStyles.main2,
                                ),
                              ),
                            ),
                            onPressed: _isLoadingTokens
                                ? null
                                : _printWithdrawTestTokens,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
