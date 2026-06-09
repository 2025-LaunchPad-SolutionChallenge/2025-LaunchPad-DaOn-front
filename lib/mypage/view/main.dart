import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/mypage/api/mypageApi.dart';
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

  final MypageApi _mypageApi = MypageApi();

  bool _isLogoutLoading = false;
  bool _isWithdrawLoading = false;
  bool _isLoadingTokens = false;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> _handleLogout() async {
    if (_isLogoutLoading || _isWithdrawLoading) return;

    final confirmed = await _showConfirmDialog(
      title: '로그아웃',
      content: '정말 로그아웃하시겠습니까?',
      confirmText: '로그아웃',
    );

    if (!confirmed) return;

    setState(() {
      _isLogoutLoading = true;
    });

    try {
      await _mypageApi.logoutUser();
      await _clearLocalAuthData();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_cleanErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLogoutLoading = false;
        });
      }
    }
  }

  Future<void> _handleWithdraw() async {
    if (_isLogoutLoading || _isWithdrawLoading) return;

    final confirmed = await _showConfirmDialog(
      title: '회원 탈퇴',
      content: '정말 회원 탈퇴하시겠습니까?\n탈퇴 후 계정 정보는 복구할 수 없습니다.',
      confirmText: '탈퇴하기',
      isDanger: true,
    );

    if (!confirmed) return;

    setState(() {
      _isWithdrawLoading = true;
    });

    try {
      await _mypageApi.withdrawUser();
      await _clearLocalAuthData();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')));

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_cleanErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawLoading = false;
        });
      }
    }
  }

  Future<void> _clearLocalAuthData() async {
    await _storage.deleteAll();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Firebase 로그아웃 실패] $e');
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                confirmText,
                style: TextStyle(
                  color: isDanger ? Colors.red : ColorStyles.main2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

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
        print('[WITHDRAW TEST] accessToken=$accessToken');
        print('[WITHDRAW TEST] refreshToken=$refreshToken');
        print('[WITHDRAW TEST] firebaseToken=$firebaseToken');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('터미널에 withdraw 테스트 토큰을 출력했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTokens = false;
        });
      }
    }
  }

  Widget _buildMenuButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: FontStyles.med16.copyWith(
              color: isDanger ? Colors.red : ColorStyles.black2,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorStyles.main2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MypageAppBarWidget(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 10.0),
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const RecoveryDashboardWidget(),
                        const SizedBox(height: 20),

                        _buildMenuButton(text: '내 식물 확인하기', onPressed: () {}),

                        _buildMenuButton(
                          text: '로그아웃',
                          onPressed: _handleLogout,
                          isLoading: _isLogoutLoading,
                        ),

                        _buildMenuButton(
                          text: '회원 탈퇴',
                          onPressed: _handleWithdraw,
                          isLoading: _isWithdrawLoading,
                          isDanger: true,
                        ),

                        if (kDebugMode) ...[
                          const SizedBox(height: 40),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
