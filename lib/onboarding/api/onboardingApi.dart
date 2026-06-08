import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';

class OnboardingApi {
  // ──────────────────────────────────────────────────────────────
  // damages 배열 기준 순서 (UI 질문 선택지 순서와 동일해야 함)
  // 이 목록이 onboardingData.dart의 options 순서와 정확히 일치해야 합니다.
  // ──────────────────────────────────────────────────────────────

  static const _floodDamageOptions = [
    '주거 공간 피해', // [0]
    '차량 피해',      // [1]
    '전기 문제',      // [2]
    '수도 문제',      // [3]
    '심리적 불안감',  // [4]
  ]; // length: 5

  static const _typhoonDamageOptions = [
    '지붕 파손',          // [0]
    '창문 파손',          // [1]
    '간판 및 구조물 피해', // [2]
    '차량 피해',          // [3]
    '전기 문제',          // [4]
    '수도 문제',          // [5]
    '부상',               // [6]
    '심리적 불안감',      // [7]
  ]; // length: 8

  static const _earthquakeDamageOptions = [
    '건물 균열 발생', // [0]
    '주거 공간 피해', // [1]
    '차량 피해',      // [2]
    '전기 문제',      // [3]
    '수도 문제',      // [4]  ← onboardingData에서 '수도 단수' → '수도 문제'로 수정됨
    '부상',           // [5]
    '심리적 불안감',  // [6]
  ]; // length: 7

  static const _fireDamageOptions = [
    '주거 공간 피해', // [0]
    '차량 피해',      // [1]
    '전기 문제',      // [2]
    '수도 문제',      // [3]
    '부상',           // [4]
    '심리적 불안감',  // [5]
    '그을음 피해',    // [6]
    '화재 잔해 발생', // [7]
  ]; // length: 8

  // ──────────────────────────────────────────────────────────────
  // Step 1: 회원가입
  // ──────────────────────────────────────────────────────────────

  Future<void> registerUser(Map<int, dynamic> userAnswers) async {
    final authService = AuthService();
    final firebaseToken = await authService.getPendingFirebaseToken();

    if (firebaseToken == null) {
      final accessToken = await authService.getAccessToken();
      if (accessToken != null) return;

      AuthService.navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
      throw Exception('로그인 정보가 만료되었습니다. 다시 로그인해 주세요.');
    }

    await authService.registerWithOnboardingData(
      firebaseToken: firebaseToken,
      name: (userAnswers[0] as String? ?? '').trim(),
      birthDate: userAnswers[1] as String? ?? '',
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Step 2: 재난 피해 현황 온보딩
  // POST /api/v1/disasters/onboarding  (accessToken 필수 — app Dio 사용)
  // ──────────────────────────────────────────────────────────────

  Future<void> submitDisasterOnboarding(
    Map<int, dynamic> userAnswers,
    String selectedDisaster,
  ) async {
    final body = buildDisasterOnboardingPayload(userAnswers, selectedDisaster);

    if (kDebugMode) {
      debugPrint('[온보딩 Step2] POST /api/v1/disasters/onboarding');
      debugPrint('[온보딩 Step2 요청 본문]');
      debugPrint('  disasterType    : ${body['disasterType']}');
      debugPrint('  safetyStatus    : ${body['safetyStatus']}');
      debugPrint('  residenceStatus : ${body['residenceStatus']}');
      debugPrint('  injuryLevel     : ${body['injuryLevel']}');
      debugPrint('  damages(${(body['damages'] as List).length}개): ${body['damages']}');
      if (body['floodLevel'] != null) debugPrint('  floodLevel      : ${body['floodLevel']}');
      if (body['waterDrainStatus'] != null) debugPrint('  waterDrainStatus: ${body['waterDrainStatus']}');
      if (body['aftershockFeeling'] != null) debugPrint('  aftershockFeeling: ${body['aftershockFeeling']}');
      if (body['fireDamageScope'] != null) debugPrint('  fireDamageScope : ${body['fireDamageScope']}');
      if (body['smokeInhalation'] != null) debugPrint('  smokeInhalation : ${body['smokeInhalation']}');
    }

    final authService = AuthService();
    // app Dio 사용 → Authorization: Bearer <accessToken> 자동 첨부
    final response = await authService.dio.post(
      '/api/v1/disasters/onboarding',
      data: body,
    );

    final status = response.statusCode ?? 0;
    final data = response.data;

    if (kDebugMode) {
      debugPrint('[온보딩 Step2 응답] $status | $data');
    }

    if (status >= 200 && status < 300) {
      final impactId = (data is Map) ? data['impactId'] : null;
      final message = (data is Map) ? (data['message'] ?? '피해 상황이 등록되었습니다') : '피해 상황이 등록되었습니다';
      // onboardingRiskLevel은 Swagger 스펙에 없어도 있으면 파싱, 없으면 null
      final riskLevel = (data is Map) ? data['onboardingRiskLevel'] : null;
      if (kDebugMode) {
        debugPrint('[온보딩 Step2] 등록 성공 | impactId=$impactId | message=$message | riskLevel=$riskLevel');
      }
      return;
    }

    final errorCode = (data is Map) ? (data['code']?.toString() ?? '') : '';
    final errorMsg = (data is Map)
        ? (data['message']?.toString() ?? '재난 정보 등록 실패 ($status)')
        : '재난 정보 등록 실패 ($status)';
    throw Exception('[$errorCode] $errorMsg');
  }

  // ──────────────────────────────────────────────────────────────
  // Flat request body 빌더
  // Swagger OnboardingRequest 스키마와 1:1 대응
  // disasterId 없음, nested detail 없음
  // ──────────────────────────────────────────────────────────────

  /// 재난 온보딩 API 요청 body를 flat 구조로 빌드합니다.
  /// damages 배열 길이가 기대값과 다르면 예외를 던집니다.
  Map<String, dynamic> buildDisasterOnboardingPayload(
    Map<int, dynamic> userAnswers,
    String selectedDisaster,
  ) {
    final disasterType = _mapDisasterType(selectedDisaster);
    final safetyStatus =
        _mapSafetyStatus((userAnswers[5] as List<String>?)?.first ?? '');
    final residenceStatus =
        _mapResidenceStatus((userAnswers[6] as List<String>?)?.first ?? '');
    final injuryLevel =
        _mapInjuryLevel((userAnswers[7] as List<String>?)?.first ?? '');

    final selectedDamages = (userAnswers[8] as List<String>?) ?? <String>[];
    final damages = _buildDamagesArray(selectedDisaster, selectedDamages);

    // 재난별 고유 필드 (해당 없는 재난은 null)
    String? floodLevel;
    String? waterDrainStatus;
    String? aftershockFeeling;
    String? fireDamageScope;
    String? smokeInhalation;

    switch (selectedDisaster) {
      case '홍수':
        final floodRaw = (userAnswers[9] as List<String>?)?.first ?? '';
        final drainRaw = (userAnswers[10] as List<String>?)?.first ?? '';
        if (floodRaw.isEmpty) throw Exception('침수 정도를 선택해 주세요.');
        if (drainRaw.isEmpty) throw Exception('물 빠짐 상태를 선택해 주세요.');
        floodLevel = _mapFloodLevel(floodRaw);
        waterDrainStatus = _mapWaterDrainStatus(drainRaw);

      case '지진':
        final aftershockRaw = (userAnswers[9] as List<String>?)?.first ?? '';
        if (aftershockRaw.isEmpty) throw Exception('여진 상태를 선택해 주세요.');
        aftershockFeeling = _mapAftershockFeeling(aftershockRaw);

      case '화재':
        final scopeRaw = (userAnswers[9] as List<String>?)?.first ?? '';
        final smokeRaw = (userAnswers[10] as List<String>?)?.first ?? '';
        if (scopeRaw.isEmpty) throw Exception('피해 범위를 선택해 주세요.');
        if (smokeRaw.isEmpty) throw Exception('연기 흡입 여부를 선택해 주세요.');
        fireDamageScope = _mapFireDamageScope(scopeRaw);
        smokeInhalation = _mapSmokeInhalation(smokeRaw);
    }

    // Swagger와 동일하게 null 값도 명시적으로 포함
    return {
      'disasterType': disasterType,
      'safetyStatus': safetyStatus,
      'residenceStatus': residenceStatus,
      'injuryLevel': injuryLevel,
      'damages': damages,
      'floodLevel': floodLevel,
      'waterDrainStatus': waterDrainStatus,
      'aftershockFeeling': aftershockFeeling,
      'fireDamageScope': fireDamageScope,
      'smokeInhalation': smokeInhalation,
    };
  }

  // ──────────────────────────────────────────────────────────────
  // damages 배열 빌더
  // 선택된 항목 Set과 기준 순서 목록을 비교해 boolean 배열 생성
  // ──────────────────────────────────────────────────────────────

  List<bool> _buildDamagesArray(
    String disasterType,
    List<String> selected,
  ) {
    final List<String> reference;
    final int expectedLength;

    switch (disasterType) {
      case '홍수':
        reference = _floodDamageOptions;
        expectedLength = 5;
      case '태풍':
        reference = _typhoonDamageOptions;
        expectedLength = 8;
      case '지진':
        reference = _earthquakeDamageOptions;
        expectedLength = 7;
      case '화재':
        reference = _fireDamageOptions;
        expectedLength = 8;
      default:
        throw Exception('알 수 없는 재난 유형: $disasterType');
    }

    final selectedSet = selected.toSet();
    final result = reference.map((opt) => selectedSet.contains(opt)).toList();

    // 방어적 길이 검증
    if (result.length != expectedLength) {
      throw Exception(
        '[VALIDATION] $disasterType damages 배열 길이 오류 — '
        '기준 목록: $expectedLength개, 실제: ${result.length}개\n'
        '기준 목록과 onboardingData.dart 질문 선택지가 일치하는지 확인하세요.',
      );
    }

    return result;
  }

  // ──────────────────────────────────────────────────────────────
  // 공통 enum 매핑
  // ──────────────────────────────────────────────────────────────

  String _mapDisasterType(String v) {
    switch (v) {
      case '홍수': return 'FLOOD';
      case '태풍': return 'TYPHOON';
      case '지진': return 'EARTHQUAKE';
      case '화재': return 'FIRE';
      default: throw Exception('알 수 없는 재난 유형: $v');
    }
  }

  String? _mapSafetyStatus(String v) {
    // Swagger: nullable
    if (v.contains('안전')) return 'SAFE';
    if (v.contains('약간')) return 'MINOR';
    if (v.contains('피해가 발생')) return 'DAMAGED';
    if (v.contains('긴급')) return 'EMERGENCY';
    return null;
  }

  String _mapResidenceStatus(String v) {
    if (v.contains('정상')) return 'LIVABLE';
    if (v.contains('파손')) return 'PARTIAL_DAMAGE';
    if (v.contains('어려워요')) return 'UNLIVABLE';
    return 'LIVABLE';
  }

  String _mapInjuryLevel(String v) {
    if (v.contains('괜찮')) return 'NONE';
    if (v.contains('경상') || v.contains('가벼운')) return 'MINOR';
    if (v.contains('중상') || v.contains('치료')) return 'SEVERE';
    return 'NONE';
  }

  // ──────────────────────────────────────────────────────────────
  // 재난별 enum 매핑 (Swagger 확인 완료)
  // ──────────────────────────────────────────────────────────────

  String _mapFloodLevel(String v) {
    // NONE | FRONT_YARD | FIRST_FLOOR | INSIDE_HOME
    if (v.contains('침수되지')) return 'NONE';
    if (v.contains('집 앞')) return 'FRONT_YARD';
    if (v.contains('1층')) return 'FIRST_FLOOR';
    if (v.contains('내부')) return 'INSIDE_HOME';
    return 'NONE';
  }

  String _mapWaterDrainStatus(String v) {
    // STILL_PRESENT | PARTIAL_DRAINED | MOSTLY_DRAINED
    if (v.contains('아직')) return 'STILL_PRESENT';
    if (v.contains('일부')) return 'PARTIAL_DRAINED';
    if (v.contains('대부분')) return 'MOSTLY_DRAINED';
    return 'STILL_PRESENT';
  }

  String _mapAftershockFeeling(String v) {
    // NONE | OCCASIONAL | CONTINUOUS
    if (v.contains('느껴지지')) return 'NONE';
    if (v.contains('가끔')) return 'OCCASIONAL';
    if (v.contains('지속')) return 'CONTINUOUS';
    return 'NONE';
  }

  String _mapFireDamageScope(String v) {
    // SMOKE_ONLY | PARTIAL_LOSS | TOTAL_LOSS
    if (v.contains('연기로 인한')) return 'SMOKE_ONLY';
    if (v.contains('일부')) return 'PARTIAL_LOSS';
    if (v.contains('전체')) return 'TOTAL_LOSS';
    return 'SMOKE_ONLY';
  }

  String _mapSmokeInhalation(String v) {
    // NONE | MILD | SEVERE
    if (v.contains('마시지')) return 'NONE';
    if (v.contains('약간')) return 'MILD';
    if (v.contains('심하게')) return 'SEVERE';
    return 'NONE';
  }
}
