import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http; // to download files from URLs

import '../models/attendance.dart';
import '../models/student.dart';

class SyncResult {
  const SyncResult({
    required this.success,
    required this.message,
    required this.studentUpdates,
    required this.attendanceUpdates,
  });

  final bool success;
  final String message;
  final List<StudentSyncUpdate> studentUpdates;
  final List<AttendanceSyncUpdate> attendanceUpdates;
}

class StudentSyncUpdate {
  const StudentSyncUpdate({
    required this.studentId,
    required this.photoUrl,
    required this.synced,
  });

  final String studentId;
  final String photoUrl;
  final bool synced;
}

class AttendanceSyncUpdate {
  const AttendanceSyncUpdate({
    required this.logId,
    required this.synced,
    this.correctedDecision,
    this.correctedReason,
  });

  final String logId;
  final bool synced;
  final AttendanceDecision? correctedDecision;
  final String? correctedReason;
}

class FirebaseService {
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth;

  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  FirebaseAuth? _auth;
  User? get currentUser => _auth?.currentUser;

  bool _backendConfigured = false;
  String _statusMessage =
      'Firebase is not initialized yet. The app will keep using local storage.';

  bool get backendConfigured => _backendConfigured;
  String get statusMessage => _statusMessage;

  Future<StudentSyncUpdate> upsertStudent(Student student) async {
    String photoUrl = student.photoUrl;
    
    if (photoUrl.isEmpty && student.photoPath.isNotEmpty) {
      final File file = File(student.photoPath);
      if (await file.exists()) {
        // --- COMPRESSION LOGIC START ---
        final bytes = await file.readAsBytes();
        img.Image? image = img.decodeImage(bytes);
        if (image != null) {
          // Resize to 400px width (maintaining aspect ratio) for thumbnails
          img.Image resized = img.copyResize(image, width: 400);
          // Compress to 70% quality JPG
          final compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
          
          final Reference ref = _storage!.ref().child('students/photos/${student.id}.jpg');
          await ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));
          photoUrl = await ref.getDownloadURL();
        }
        // --- COMPRESSION LOGIC END ---
      }
    }

    await _firestore!.collection('students').doc(student.id).set(
      <String, dynamic>{
        'id': student.id,
        'qrPayload': student.qrPayload,
        'name': student.name,
        'prn': student.prn,
        'phoneNumber': student.phoneNumber,
        'membershipActive': student.membershipActive,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(student.createdAt),
        'updatedAt': Timestamp.fromDate(student.updatedAt),
      },
      SetOptions(merge: true),
    );

    return StudentSyncUpdate(
      studentId: student.id,
      photoUrl: photoUrl,
      synced: true,
    );
  }

  Future<UserCredential?> signIn(String email, String password) async {
  try {
    return await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  } catch (e) {
    rethrow; // Let the UI handle the specific error message
  }
}

Future<void> signOut() async {
    try {
      // 1. Clear Firestore persistence to kill any active listeners/cache
      // This prevents 'Permission Denied' loops after the UID becomes null
      if (_firestore != null) {
        await _firestore!.terminate();
        await _firestore!.clearPersistence();
        // Re-enable it for the next user who might log in
        _firestore = FirebaseFirestore.instance; 
      }
      
      // 2. Perform actual Auth sign out
      await _auth?.signOut();
      
      // 3. Reset local status
      _backendConfigured = false;
      _statusMessage = 'Firebase ready. Please sign in.';
      
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
 }

Stream<String> userRoleStream(String uid) {
    return _firestore!
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String? ?? 'employee')
        .handleError((error) {
          debugPrint('Stream error (likely sign-out): $error');
          return 'employee'; // Fallback value on error
        });
  }

  // Add this method to handle the first-time check
Future<void> ensureUserExists(User user) async {
  final userDoc = await _firestore!.collection('users').doc(user.uid).get();

  if (!userDoc.exists) {
    // This is a first-time login
    await _firestore!.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': 'employee', // Default role
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// Add this to retrieve the role later for UI logic
Future<String> getUserRole(String uid) async {
  final doc = await _firestore!.collection('users').doc(uid).get();
  return doc.data()?['role'] as String? ?? 'employee';
}

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firestore ??= FirebaseFirestore.instance;
      _storage ??= FirebaseStorage.instance;
      _auth ??= FirebaseAuth.instance;
      
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Re-apply settings in case firestore was terminated during a previous logout
      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        // Settings can only be set once per instance; ignore if already set
      }
      
      if (_auth!.currentUser != null) {
        _backendConfigured = true;
        _statusMessage = 'Firebase connected as ${_auth!.currentUser?.email}';
      } else {
        _backendConfigured = true; // Firestore is ready, just waiting for auth
        _statusMessage = 'Firebase ready. Please sign in.';
      }
    } catch (error) {
      _backendConfigured = false;
      _statusMessage = 'Firebase unavailable. Falling back to local storage. $error';
    }
  }

  Future<List<Student>> fetchStudents() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore!.collection('students').get();
    return snapshot.docs.map(_studentFromSnapshot).toList();
  }

  Future<List<AttendanceLog>> fetchAttendanceLogs() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore!
        .collection('attendance_logs')
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();
    return snapshot.docs.map(_attendanceFromSnapshot).toList();
  }

  Future<SyncResult> syncPendingAttendance({
    required List<Student> pendingStudents,
    required List<AttendanceLog> pendingLogs,
  }) async {
    if (!backendConfigured) {
      return SyncResult(
        success: false,
        message: _statusMessage,
        studentUpdates: const <StudentSyncUpdate>[],
        attendanceUpdates: const <AttendanceSyncUpdate>[],
      );
    }

    final List<StudentSyncUpdate> studentUpdates = <StudentSyncUpdate>[];
    final List<AttendanceSyncUpdate> attendanceUpdates =
        <AttendanceSyncUpdate>[];
    int failures = 0;

    for (final Student student in pendingStudents) {
      try {
        studentUpdates.add(await upsertStudent(student));
      } catch (_) {
        failures += 1;
      }
    }

    for (final AttendanceLog log in pendingLogs) {
      try {
        attendanceUpdates.add(await _syncAttendanceLog(log));
      } catch (_) {
        failures += 1;
      }
    }

    final bool success = failures == 0;
    return SyncResult(
      success: success,
      message:
          'Firebase sync finished. Students: ${studentUpdates.length}, attendance logs: ${attendanceUpdates.length}, failures: $failures.',
      studentUpdates: studentUpdates,
      attendanceUpdates: attendanceUpdates,
    );
  }

  Future<AttendanceSyncUpdate> _syncAttendanceLog(AttendanceLog log) async {
    final DocumentReference<Map<String, dynamic>> logRef =
        _firestore!.collection('attendance_logs').doc(log.id);

    if (log.decision == AttendanceDecision.denied) {
      await logRef.set(_attendanceMap(log), SetOptions(merge: true));
      return AttendanceSyncUpdate(logId: log.id, synced: true);
    }

    final String duplicateKey =
        '${log.studentId}_${log.mealType.name}_${log.dayKey}';
    final DocumentReference<Map<String, dynamic>> keyRef =
        _firestore!.collection('attendance_keys').doc(duplicateKey);

    return _firestore!.runTransaction<AttendanceSyncUpdate>(
      (Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> keySnapshot =
            await tx.get(keyRef);

        if (keySnapshot.exists &&
            keySnapshot.data()?['logId'] != null &&
            keySnapshot.data()!['logId'] != log.id) {
          const String conflictReason =
              'Rejected by cloud duplicate protection for this meal.';
          tx.set(
            logRef,
            _attendanceMap(
              log.copyWith(
                decision: AttendanceDecision.denied,
                reason: conflictReason,
              ),
            ),
            SetOptions(merge: true),
          );
          return const AttendanceSyncUpdate(
            logId: '',
            synced: true,
            correctedDecision: AttendanceDecision.denied,
            correctedReason: conflictReason,
          );
        }

        tx.set(
          keyRef,
          <String, dynamic>{
            'studentId': log.studentId,
            'mealType': log.mealType.name,
            'dayKey': log.dayKey,
            'logId': log.id,
            'timestamp': Timestamp.fromDate(log.timestamp),
          },
          SetOptions(merge: true),
        );
        tx.set(logRef, _attendanceMap(log), SetOptions(merge: true));
        return AttendanceSyncUpdate(logId: log.id, synced: true);
      },
    ).then((AttendanceSyncUpdate update) {
      if (update.logId.isEmpty) {
        return AttendanceSyncUpdate(
          logId: log.id,
          synced: true,
          correctedDecision: update.correctedDecision,
          correctedReason: update.correctedReason,
        );
      }
      return update;
    });
  }

  Student _studentFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    return Student(
      id: data['id'] as String? ?? snapshot.id,
      qrPayload: data['qrPayload'] as String? ?? snapshot.id,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      prn: data['prn'] as String? ?? '',
      membershipActive: data['membershipActive'] as bool? ?? true,
      deleted: data['deleted'] as bool? ?? false,
      photoPath: '',
      photoUrl: data['photoUrl'] as String? ?? '',
      syncedToCloud: true,
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: _dateFromFirestore(data['updatedAt']),
    );
  }

  Future<void> deleteStudentData(String studentId, String? photoUrl) async {
    // 1. Delete photo from Storage first
    // We use the ID-based path because refFromURL can sometimes fail if the URL is old
    try {
      final Reference photoRef = _storage!.ref().child('students/photos/$studentId.jpg');
      await photoRef.delete();
    } catch (e) {
      debugPrint('Storage photo delete skipped (might not exist): $e');
    }

    final batch = _firestore!.batch();

    // 2. Delete the Student document
    batch.delete(_firestore!.collection('students').doc(studentId));

    // 3. Cleanup all attendance logs for this student
    final logs = await _firestore!
        .collection('attendance_logs')
        .where('studentId', isEqualTo: studentId)
        .get();
    for (var doc in logs.docs) {
      batch.delete(doc.reference);
    }

    // 4. Cleanup duplicate protection keys
    final keys = await _firestore!
        .collection('attendance_keys')
        .where('studentId', isEqualTo: studentId)
        .get();
    for (var doc in keys.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  AttendanceLog _attendanceFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    final DateTime timestamp = _dateFromFirestore(data['timestamp']);
    return AttendanceLog(
      id: data['id'] as String? ?? snapshot.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      mealType:
          MealType.values.byName(data['mealType'] as String? ?? MealType.lunch.name),
      decision: AttendanceDecision.values.byName(
        data['decision'] as String? ?? AttendanceDecision.denied.name,
      ),
      reason: data['reason'] as String? ?? '',
      timestamp: timestamp,
      deviceId: data['deviceId'] as String? ?? 'firebase',
      syncedToCloud: true,
      dayKey: data['dayKey'] as String? ?? _buildDayKey(timestamp),
    );
  }

  Map<String, dynamic> _attendanceMap(AttendanceLog log) {
    return <String, dynamic>{
      'id': log.id,
      'studentId': log.studentId,
      'studentName': log.studentName,
      'mealType': log.mealType.name,
      'decision': log.decision.name,
      'reason': log.reason,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'deviceId': log.deviceId,
      'dayKey': log.dayKey,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime _dateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  String _buildDayKey(DateTime timestamp) {
    final String month = timestamp.month.toString().padLeft(2, '0');
    final String day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }

  Future<File?> downloadStudentPhoto(String url, String localPath) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
  } catch (e) {
    if (kDebugMode) { // only use print statement if in debug mode
      print('Error downloading image: $e');
    }
  }
  return null;
}

}
