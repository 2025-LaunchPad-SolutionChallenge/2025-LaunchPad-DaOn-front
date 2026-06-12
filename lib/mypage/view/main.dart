import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/core/service/selected_disaster_service.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/mypage/api/mypageApi.dart';
import 'package:project_daon/mypage/model/userModel.dart';
import 'package:project_daon/mypage/view/profileEditPage.dart';
import 'package:project_daon/mypage/widget/myPageAppBarWidget.dart';
import 'package:project_daon/mypage/widget/myProfileWidget.dart';
import 'package:project_daon/mypage/widget/recoverydashboardWidget.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';
import 'package:project_daon/onboarding/view/onboardingController.dart';
import 'package:project_daon/onboarding/view/onboardingLocationConfirmPage.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  UserProfile? _profile;
  ResidenceStatus? _residenceStatus;
  HomeSummary? _homeSummary;
  RecoveryStageResponse? _recoveryStage;
  RecoveryProgress? _recoveryProgress;
  List<UserDisasterSummary> _disasters = [];
  bool _isProfileLoading = true;

  final MypageApi _mypageApi = MypageApi();
  final HomeApi _homeApi = HomeApi();

  bool _isLogoutLoading = false;
  bool _isWithdrawLoading = false;
  bool _isLoadingTokens = false;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ── 현재 선택된 재난 (모든 재난 목록 기준) ──
  UserDisasterSummary? get _selectedDisasterSummary {
    final id = SelectedDisasterService.instance.selectedId.value;
    if (id == null || _disasters.isEmpty) return null;
    for (final d in _disasters) {
      if (d.userDisasterId == id) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    SelectedDisasterService.instance.selectedId.addListener(
      _onSelectedDisasterChanged,
    );
    _loadMyPageData();
  }

  @override
  void dispose() {
    SelectedDisasterService.instance.selectedId.removeListener(
      _onSelectedDisasterChanged,
    );
    super.dispose();
  }

  void _onSelectedDisasterChanged() {
    if (!mounted) return;
    final id = SelectedDisasterService.instance.selectedId.value;
    if (kDebugMode) debugPrint('[마이페이지] 선택 재난 변경 감지: userDisasterId=$id');
    setState(() {});
    if (id != null) _reloadRecoveryStage(id);
  }

  Future<void> _reloadRecoveryStage(int id) async {
    try {
      final results = await Future.wait([
        _homeApi.getRecoveryStage(id),
        _homeApi.fetchRecoveryProgress(id),
      ]);
      if (!mounted) return;
      setState(() {
        _recoveryStage = results[0] as RecoveryStageResponse;
        _recoveryProgress = results[1] as RecoveryProgress;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[마이페이지] 회복 단계 재조회 실패: $e');
    }
  }

  Future<void> refreshRecoveryAndProgress() async {
    await _loadMyPageData();
  }

  Future<void> _loadMyPageData() async {
    if (!mounted) return;
    setState(() => _isProfileLoading = true);

    // 저장된 선택 재난 ID가 없으면 스토리지에서 복원
    if (SelectedDisasterService.instance.selectedId.value == null) {
      await SelectedDisasterService.instance.initFromStorage();
    }

    UserProfile? profile;
    ResidenceStatus? residenceStatus;
    HomeSummary? homeSummary;
    List<UserDisasterSummary> disasters = [];

    await Future.wait([
      _mypageApi
          .getUserProfile()
          .then<void>((p) {
            profile = p;
          })
          .catchError((Object e) {
            if (kDebugMode) debugPrint('[마이페이지] 프로필 조회 실패: $e');
          }),
      _mypageApi.getResidenceStatus().then<void>((r) {
        residenceStatus = r;
      }),
      _homeApi
          .getHomeSummary()
          .then<void>((s) {
            homeSummary = s;
          })
          .catchError((Object e) {
            if (kDebugMode) debugPrint('[마이페이지] 홈 요약 조회 실패: $e');
          }),
      _homeApi
          .getDisasterList()
          .then<void>((r) {
            disasters = r.content;
            if (kDebugMode) {
              debugPrint(
                '[마이페이지] 재난 목록: ${disasters.length}개 (총 ${r.totalElements}건)',
              );
              for (final d in disasters) {
                debugPrint(
                  '  ㄴ id=${d.userDisasterId} | ${d.disasterTypeName} | ${d.status} | 회복률=${d.recoveryProgress.toStringAsFixed(1)}% | ${d.occurredAt} | 장소=${d.address ?? '없음'}',
                );
              }
            }
          })
          .catchError((Object e) {
            if (kDebugMode) debugPrint('[마이페이지] 재난 목록 조회 실패: $e');
          }),
    ]);

    // 선택된 재난 ID 결정
    final svc = SelectedDisasterService.instance;
    final savedId = svc.selectedId.value;
    int? activeId;

    if (savedId != null && disasters.any((d) => d.userDisasterId == savedId)) {
      activeId = savedId;
    } else {
      // 저장값이 없거나 목록에 없으면 홈 요약 ID 또는 첫 번째 재난으로 fallback
      activeId =
          homeSummary?.userDisasterId ??
          (disasters.isNotEmpty ? disasters.first.userDisasterId : null);
      if (activeId != null) await svc.select(activeId);
    }

    RecoveryStageResponse? recoveryStage;
    RecoveryProgress? recoveryProgress;
    if (activeId != null) {
      try {
        final results = await Future.wait([
          _homeApi.getRecoveryStage(activeId),
          _homeApi.fetchRecoveryProgress(activeId),
        ]);
        recoveryStage = results[0] as RecoveryStageResponse;
        recoveryProgress = results[1] as RecoveryProgress;
      } catch (e) {
        if (kDebugMode) debugPrint('[마이페이지] 회복 단계/진행도 조회 실패: $e');
        if (recoveryStage == null && activeId != null) {
          try {
            recoveryStage = await _homeApi.getRecoveryStage(activeId);
          } catch (_) {}
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _residenceStatus = residenceStatus;
      _homeSummary = homeSummary;
      _recoveryStage = recoveryStage;
      _recoveryProgress = recoveryProgress;
      _disasters = disasters;
      _isProfileLoading = false;
    });
  }

  Future<void> _handleProfileEdit() async {
    final profile = _profile;
    if (profile == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditPage(profile: profile)),
    );

    if (updated == true) {
      await _loadMyPageData();
    }
  }

  Future<void> _handleAddDisaster() async {
    final accessToken = await AuthService().getAccessToken();

    if (!mounted) return;
    if (accessToken == null || accessToken.isEmpty) {
      _showSnackBar('로그인이 필요합니다. 다시 로그인해 주세요.');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    if (kDebugMode) debugPrint('[마이페이지] 재난 추가 — 위치 수집 시작');

    // Step 1: 재난 발생 위치 수집
    final locationResult = await Navigator.push<LocationConfirmResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingLocationConfirmPage(
          initialQuery: '',
          confirmLabel: '다음',
        ),
      ),
    );

    if (!mounted) return;
    if (locationResult == null) return; // 사용자가 취소

    if (kDebugMode) {
      debugPrint('[마이페이지] 위치 수집 완료: ${locationResult.location.displayAddress}');
      debugPrint('[마이페이지] 재난 추가 온보딩 시작');
    }

    // Step 2: 재난 정보 입력
    final newId = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingController(
          addDisasterMode: true,
          locationResult: locationResult,
        ),
      ),
    );

    if (!mounted) return;

    if (newId != null) {
      _showSnackBar('새 재난이 등록되었습니다.');
      await _loadMyPageData();
    }
  }

  Future<void> _handleCloseDisaster(int id, String action) async {
    final now = DateTime.now().toIso8601String().substring(0, 19);
    try {
      await _mypageApi.closeDisaster(
        userDisasterId: id,
        action: action,
        endedAt: now,
      );
      await _loadMyPageData();
    } catch (e) {
      if (mounted) _showSnackBar(_cleanErrorMessage(e));
    }
  }

  Future<void> _handleDisasterSelected(int id) async {
    if (kDebugMode) debugPrint('[마이페이지] 재난 선택: userDisasterId=$id');
    await SelectedDisasterService.instance.select(id);
    if (mounted) setState(() {});
    _reloadRecoveryStage(id);
  }

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
    await SelectedDisasterService.instance.clear();

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
    final profile = _profile;
    final residenceVerified =
        _residenceStatus?.verified ?? profile?.residenceVerified ?? false;

    // 선택된 재난의 disasterTypeName (없으면 홈 요약 fallback)
    final activeDisasterTypeName =
        _selectedDisasterSummary?.disasterTypeName ??
        _homeSummary?.disasterTypeName;

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

            colors: [
              ColorStyles.main2, // 상단의 민트/그린
              ColorStyles.main3, // 하단의 연노랑
            ],

            stops: [0.01, 0.8],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _isProfileLoading
                  ? const SizedBox(
                      height: 210,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ColorStyles.white,
                        ),
                      ),
                    )
                  : MyProfileWidget(
                      name: profile?.displayName ?? '사용자',
                      stageId: _recoveryStage?.stageId,
                      stageName: _recoveryStage?.stageName,
                      disasterTypeName: activeDisasterTypeName,
                      profileImageUrl: profile?.profileImage,
                      residenceVerified: residenceVerified,
                    ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                width: double.infinity,
                child: ChecklistProgessBar(
                  // 모든 진행률 값은 0~100 스케일. ChecklistProgessBar도 0~100 기대.
                  currentCheck:
                      (_recoveryProgress?.recoveryScore ??
                              _homeSummary?.recoveryProgress ??
                              0.0)
                          .clamp(0.0, 100.0),
                  text: '회복률',
                  textcolor: ColorStyles.white,
                  progresscolor: ColorStyles.main3,
                  backgroundcolor: ColorStyles.white,
                ),
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
                        RecoveryDashboardWidget(
                          disasters: _disasters,
                          selectedDisasterId:
                              SelectedDisasterService.instance.selectedId.value,
                          onDisasterSelected: _handleDisasterSelected,
                          onAddDisaster: _handleAddDisaster,
                          onCloseDisaster: _handleCloseDisaster,
                        ),
                        const SizedBox(height: 16),

                        _buildMenuButton(
                          text: '프로필 수정하기',
                          onPressed: _isProfileLoading
                              ? null
                              : _handleProfileEdit,
                        ),

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
