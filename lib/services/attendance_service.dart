import '../models/attendance.dart';

class AttendanceService {
  const AttendanceService();

  String buildDayKey(DateTime timestamp) {
    final String month = timestamp.month.toString().padLeft(2, '0');
    final String day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }

  String buildDuplicateKey({
    required String studentId,
    required MealType mealType,
    required DateTime timestamp,
  }) {
    return '$studentId-${mealType.name}-${buildDayKey(timestamp)}';
  }
}
