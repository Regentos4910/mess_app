import '../models/attendance.dart';
import '../models/student.dart';

class SyncResult {
  const SyncResult({
    required this.success,
    required this.message,
    required this.syncedLogIds,
  });

  final bool success;
  final String message;
  final List<String> syncedLogIds;
}

class FirebaseService {
  const FirebaseService();

  bool get backendConfigured => false;

  Future<SyncResult> syncPendingAttendance({
    required List<AttendanceLog> pendingLogs,
    required List<Student> students,
  }) async {
    if (!backendConfigured) {
      return const SyncResult(
        success: false,
        message: 'Firebase sync is disabled until backend configuration is added.',
        syncedLogIds: <String>[],
      );
    }

    return SyncResult(
      success: true,
      message: 'Synced ${pendingLogs.length} attendance records.',
      syncedLogIds: pendingLogs.map((AttendanceLog log) => log.id).toList(),
    );
  }
}
