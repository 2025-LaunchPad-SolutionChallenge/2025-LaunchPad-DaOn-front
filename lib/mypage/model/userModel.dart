class UserProfile {
  final int userId;
  final String name;
  final String? nickname;
  final String? birthDate;
  final int? age;
  final String? profileImage;
  final bool residenceVerified;
  final String? addressName;
  // NOTE: GET /users/me 명세에 level, disaster 없음.
  // 실제 백엔드 응답에 포함될 경우 자동 파싱됨. 없으면 null.
  final int? level;
  final String? disaster;

  const UserProfile({
    required this.userId,
    required this.name,
    this.nickname,
    this.birthDate,
    this.age,
    this.profileImage,
    this.residenceVerified = false,
    this.addressName,
    this.level,
    this.disaster,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String?,
      birthDate: json['birthDate'] as String?,
      age: (json['age'] as num?)?.toInt(),
      profileImage: json['profileImage'] as String?,
      residenceVerified: json['residenceVerified'] as bool? ?? false,
      addressName: json['addressName'] as String?,
      level: (json['level'] as num?)?.toInt(),
      disaster: json['disaster'] as String?,
    );
  }

  String get displayName {
    final n = name?.trim();
    return (n != null && n.isNotEmpty) ? n : name;
  }
}

class ResidenceStatus {
  final String status;
  final bool verified;
  final double? distanceKm;
  final double? thresholdKm;
  final int? verificationCount;
  final String? verifiedAt;
  final String? expiresAt;
  final int? daysUntilExpiry;
  final String? message;

  const ResidenceStatus({
    required this.status,
    required this.verified,
    this.distanceKm,
    this.thresholdKm,
    this.verificationCount,
    this.verifiedAt,
    this.expiresAt,
    this.daysUntilExpiry,
    this.message,
  });

  factory ResidenceStatus.fromJson(Map<String, dynamic> json) {
    return ResidenceStatus(
      status: json['status'] as String? ?? 'NONE',
      verified: json['verified'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      thresholdKm: (json['thresholdKm'] as num?)?.toDouble(),
      verificationCount: (json['verificationCount'] as num?)?.toInt(),
      verifiedAt: json['verifiedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
