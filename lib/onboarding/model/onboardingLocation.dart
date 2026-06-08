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
