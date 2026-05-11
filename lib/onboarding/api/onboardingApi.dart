import 'package:dio/dio.dart';

class OnboardingApi {
  final Dio _dio = Dio();

  Future<void> submitSurvey(
    Map<int, dynamic> userAnswers,
    String selectedDisaster,
  ) async {
    Map<String, dynamic> apiPayload = _preparePayload(
      userAnswers,
      selectedDisaster,
    );

    print('=====================================');
    print('🚀 [API 전송 시뮬레이션] 백엔드로 보낼 JSON 데이터:');
    print(apiPayload);
    print('=====================================');

    /* // 나중에 API 통신할 때 주석 해제하세요
    try {
      final response = await _dio.post('엔드포인트 URL', data: apiPayload);
      print('성공: \${response.data}');
    } catch (e) {
      print('에러: \$e');
    }
    */
  }

  Map<String, dynamic> _preparePayload(
    Map<int, dynamic> answers,
    String disaster,
  ) {
    // 1. 프로필 정보 (인덱스 0~3) -> 텍스트 필드이므로 String
    Map<String, dynamic> payload = {
      "name": answers[0] as String? ?? "",
      "birthdate": answers[1] as String? ?? "",
      "nickname": answers[2] as String? ?? "",
      "address": answers[3] as String? ?? "",
      "disasterType": disaster,
    };

    // 2. ENUM 매핑 함수들
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

    // 3. Boolean 행렬 매핑 함수
    List<bool> mapDamages(List<String> selected, List<String> reference) {
      return reference.map((item) => selected.contains(item)).toList();
    }

    // ⭐ 4. 실제 코드 순서에 맞춘 공통 문항 파싱
    // 인덱스 5: 상태 / 인덱스 6: 거주 / 인덱스 7: 부상
    String statusStr = (answers[5] as List<String>?)?.first ?? "";
    String livableStr = (answers[6] as List<String>?)?.first ?? "";
    String injuryStr = (answers[7] as List<String>?)?.first ?? "";

    payload["status"] = mapStatus(statusStr);
    payload["livable"] = mapLivable(livableStr);
    payload["injury"] = mapInjury(injuryStr);

    // ⭐ 5. 복수 선택 피해 종류 파싱 (인덱스 8)
    List<String> damagesList = (answers[8] as List<String>?) ?? [];

    // ⭐ 6. 재난별 Boolean 행렬 & 특화 질문 파싱
    if (disaster == '홍수') {
      List<String> ref = ['주거 공간 피해', '차량 피해', '전기 문제', '수도 문제', '심리적 불안감'];
      payload["damages"] = mapDamages(damagesList, ref);

      // 특화 질문 (인덱스 9: 침수 정도 / 인덱스 10: 물 빠짐)
      payload["floodLevel"] = (answers[9] as List<String>?)?.first ?? "";
      payload["waterReceded"] = (answers[10] as List<String>?)?.first ?? "";
    } else if (disaster == '태풍') {
      List<String> ref = [
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
      // 태풍은 특화 질문 없음
    } else if (disaster == '지진') {
      List<String> ref = [
        '건물 균열 발생',
        '주거 공간 피해',
        '차량 피해',
        '전기 문제',
        '수도 단수',
        '부상',
        '심리적 불안감',
      ];
      payload["damages"] = mapDamages(damagesList, ref);

      // 특화 질문 (인덱스 9: 여진 체감)
      payload["aftershock"] = (answers[9] as List<String>?)?.first ?? "";
    } else if (disaster == '화재') {
      List<String> ref = [
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

      // 특화 질문 (인덱스 9: 피해 범위 / 인덱스 10: 연기 흡입)
      payload["fireScope"] = (answers[9] as List<String>?)?.first ?? "";
      payload["smokeInhalation"] = (answers[10] as List<String>?)?.first ?? "";
    }

    return payload;
  }
}
