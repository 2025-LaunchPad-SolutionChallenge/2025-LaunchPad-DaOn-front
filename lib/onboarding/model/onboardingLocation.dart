class OnboardingLocation {
  final String address;
  final String roadAddress;
  final String jibunAddress;

  final String sido;
  final String sigungu;
  final String dong;

  final String? legalDong;
  final String? administrativeCode;

  final double? latitude;
  final double? longitude;

  final String? placeName;
  final bool isVerified;

  const OnboardingLocation({
    required this.address,
    required this.roadAddress,
    required this.jibunAddress,
    required this.sido,
    required this.sigungu,
    required this.dong,
    required this.latitude,
    required this.longitude,
    this.legalDong,
    this.administrativeCode,
    this.placeName,
    this.isVerified = true,
  });

  factory OnboardingLocation.manual(String address) {
    return OnboardingLocation(
      address: address,
      roadAddress: '',
      jibunAddress: address,
      sido: '',
      sigungu: '',
      dong: '',
      latitude: null,
      longitude: null,
      isVerified: false,
    );
  }

  String get displayAddress {
    if (roadAddress.trim().isNotEmpty) return roadAddress;
    if (address.trim().isNotEmpty) return address;
    return jibunAddress;
  }

  String get areaLabel {
    return [
      sido,
      sigungu,
      dong,
    ].where((text) => text.trim().isNotEmpty).join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'address': displayAddress,
      'roadAddress': roadAddress,
      'jibunAddress': jibunAddress,
      'sido': sido,
      'sigungu': sigungu,
      'dong': dong,
      'legalDong': legalDong,
      'administrativeCode': administrativeCode,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'isVerified': isVerified,
    };
  }
}

/// 거주지 확인 페이지에서 팝할 때 재난 장소 + 현재 GPS를 함께 전달합니다.
/// verify API 호출 시점은 register 성공 이후(OnboardingController)입니다.
class LocationConfirmResult {
  final OnboardingLocation location;
  final double currentLatitude;
  final double currentLongitude;

  /// 현재 GPS를 역지오코딩한 주소. 역지오코딩 실패 시 빈 문자열.
  /// TODO: currentAddress가 빈 문자열인 경우 백엔드 허용 여부를 확인해주세요.
  final String currentAddress;

  const LocationConfirmResult({
    required this.location,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentAddress,
  });
}
