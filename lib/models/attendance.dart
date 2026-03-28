enum MealType { breakfast, lunch, dinner }

enum AttendanceDecision { allowed, denied }

class AttendanceLog {
  AttendanceLog({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.mealType,
    required this.decision,
    required this.reason,
    required this.timestamp,
    required this.deviceId,
    required this.syncedToCloud,
    required this.dayKey,
  });

  final String id;
  final String studentId;
  final String studentName;
  final MealType mealType;
  final AttendanceDecision decision;
  final String reason;
  final DateTime timestamp;
  final String deviceId;
  final bool syncedToCloud;
  final String dayKey;

  AttendanceLog copyWith({
    String? id,
    String? studentId,
    String? studentName,
    MealType? mealType,
    AttendanceDecision? decision,
    String? reason,
    DateTime? timestamp,
    String? deviceId,
    bool? syncedToCloud,
    String? dayKey,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      mealType: mealType ?? this.mealType,
      decision: decision ?? this.decision,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
      dayKey: dayKey ?? this.dayKey,
    );
  }

  String get mealLabel => switch (mealType) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
      };

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'mealType': mealType.name,
      'decision': decision.name,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'syncedToCloud': syncedToCloud,
      'dayKey': dayKey,
    };
  }

  factory AttendanceLog.fromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      mealType: MealType.values.byName(map['mealType'] as String),
      decision: AttendanceDecision.values.byName(
        map['decision'] as String,
      ),
      reason: map['reason'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      deviceId: map['deviceId'] as String,
      syncedToCloud: map['syncedToCloud'] as bool? ?? false,
      dayKey: map['dayKey'] as String,
    );
  }
}
