class AppKeys {
  AppKeys._();

  static const String kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  static const String naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
  );

  static void validate() {
    final missingKeys = <String>[
      if (kakaoRestApiKey.isEmpty) 'KAKAO_REST_API_KEY',
      if (naverMapClientId.isEmpty) 'NAVER_MAP_CLIENT_ID',
    ];

    if (missingKeys.isNotEmpty) {
      throw StateError('필수 API Key가 설정되지 않았습니다: ${missingKeys.join(', ')}');
    }
  }
}
