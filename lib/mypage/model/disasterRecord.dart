// 상태를 나타내는 Enum
enum RecoveryStatus { recovering, completed, archived }

// 카드에 들어갈 재난 데이터 모델
class DisasterRecord {
  final String title;
  final String date;
  final String location;
  final String damageDetail;
  final RecoveryStatus status;

  DisasterRecord({
    required this.title,
    required this.date,
    required this.location,
    required this.damageDetail,
    required this.status,
  });
}
