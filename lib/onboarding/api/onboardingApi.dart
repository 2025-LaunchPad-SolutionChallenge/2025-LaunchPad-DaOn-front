import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:project_daon/core/service/auth_service.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';

class OnboardingApi {

  /// 온보딩 완료 시 name/birthDate와 pending firebase token으로 회원가입 처리
  /// pending firebase token이 없으면 (기존 사용자) skip
  Future<void> registerUser(Map<int, dynamic> userAnswers) async {
    final authService = AuthService();
    final firebaseToken = await authService.getPendingFirebaseToken();
    if (firebaseToken == null) return;

    await authService.registerWithOnboardingData(
      firebaseToken: firebaseToken,
      name: userAnswers[0] as String? ?? '',
      birthDate: userAnswers[1] as String? ?? '',
    );
  }

  Future<void> submitSurvey(
    Map<int, dynamic> userAnswers,
    String selectedDisaster,
  ) async {
    final apiPayload = buildPayload(userAnswers, selectedDisaster);

    debugPrint('=====================================');
    debugPrint('🚀 [온보딩 최종 저장 데이터]');
    debugPrint(const JsonEncoder.withIndent('  ').convert(apiPayload));
    debugPrint('=====================================');

    /*
    실제 백엔드 저장을 붙일 때는 아래 주석을 해제하고 URL을 넣으면 돼.

    try {
      final response = await _dio.post(
        '백엔드_온보딩_저장_URL',
        data: apiPayload,
      );

      debugPrint('온보딩 저장 성공: ${response.data}');
    } catch (e) {
      debugPrint('온보딩 저장 실패: $e');
      rethrow;
    }
    */
  }

  Map<String, dynamic> buildPayload(
    Map<int, dynamic> answers,
    String disaster,
  ) {
    final addressAnswer = answers[3];

    final OnboardingLocation? location = addressAnswer is OnboardingLocation
        ? addressAnswer
        : null;

    final String addressText =
        location?.displayAddress ??
        (addressAnswer is String ? addressAnswer : '');

    Map<String, dynamic> payload = {
      "name": answers[0] as String? ?? "",
      "birthdate": answers[1] as String? ?? "",
      "nickname": answers[2] as String? ?? "",

      // 기존 백엔드 호환용 주소
      "address": addressText,

      // 지도 검색 후 추가로 저장할 수 있는 위치 정보
      "addressDong": location?.dong ?? "",
      "addressSido": location?.sido ?? "",
      "addressSigungu": location?.sigungu ?? "",
      "latitude": location?.latitude,
      "longitude": location?.longitude,
      "administrativeCode": location?.administrativeCode,

      "disasterType": disaster,
    };

    String mapStatus(String value) {
      if (value.contains('안전')) return 'SAFE';
      if (value.contains('경미') || value.contains('약간')) return 'MINOR';
      if (value.contains('피해')) return 'DAMAGED';
      if (value.contains('긴급')) return 'EMERGENCY';
      return 'UNKNOWN';
    }

    String mapLivable(String value) {
      if (value.contains('정상') || value.contains('가능')) return 'LIVABLE';
      if (value.contains('파손')) return 'PARTIAL_DAMAGE';
      if (value.contains('어려워요') || value.contains('불가')) return 'UNLIVABLE';
      return 'UNKNOWN';
    }

    String mapInjury(String value) {
      if (value.contains('없음') || value.contains('괜찮')) return 'NONE';
      if (value.contains('경상') || value.contains('가벼운')) return 'MINOR';
      if (value.contains('중상') || value.contains('치료')) return 'SEVERE';
      return 'UNKNOWN';
    }

    List<bool> mapDamages(List<String> selected, List<String> reference) {
      return reference.map((item) => selected.contains(item)).toList();
    }

    final String statusStr = (answers[5] as List<String>?)?.first ?? "";
    final String livableStr = (answers[6] as List<String>?)?.first ?? "";
    final String injuryStr = (answers[7] as List<String>?)?.first ?? "";

    payload["status"] = mapStatus(statusStr);
    payload["livable"] = mapLivable(livableStr);
    payload["injury"] = mapInjury(injuryStr);

    final List<String> damagesList = (answers[8] as List<String>?) ?? [];

    if (disaster == '홍수') {
      final ref = ['주거 공간 피해', '차량 피해', '전기 문제', '수도 문제', '심리적 불안감'];
      payload["damages"] = mapDamages(damagesList, ref);
      payload["floodLevel"] = (answers[9] as List<String>?)?.first ?? "";
      payload["waterReceded"] = (answers[10] as List<String>?)?.first ?? "";
    } else if (disaster == '태풍') {
      final ref = [
        '지붕 파손',
        '창문 파손',
        '간판 및 구조물 피해',
        '차량 피해',
        '전기 문제',
        '수도 문제',
        '부상',
        '심리적 불안감',
      ];
      payload["damages"] = mapDamages(damagesList, ref);
    } else if (disaster == '지진') {
      final ref = [
        '건물 균열 발생',
        '주거 공간 피해',
        '차량 피해',
        '전기 문제',
        '수도 단수',
        '부상',
        '심리적 불안감',
      ];
      payload["damages"] = mapDamages(damagesList, ref);
      payload["aftershock"] = (answers[9] as List<String>?)?.first ?? "";
    } else if (disaster == '화재') {
      final ref = [
        '주거 공간 피해',
        '차량 피해',
        '전기 문제',
        '수도 문제',
        '부상',
        '심리적 불안감',
        '그을음 피해',
        '화재 잔해 발생',
      ];
      payload["damages"] = mapDamages(damagesList, ref);
      payload["fireScope"] = (answers[9] as List<String>?)?.first ?? "";
      payload["smokeInhalation"] = (answers[10] as List<String>?)?.first ?? "";
    }

    payload.removeWhere((key, value) => value == null);

    return payload;
  }
}
