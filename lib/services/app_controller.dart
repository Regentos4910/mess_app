import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance.dart';
import '../models/student.dart';
import 'attendance_service.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';
import 'student_service.dart';

class StudentDraft {
  const StudentDraft({
    required this.name,
    required this.prn,
    required this.phoneNumber, // Added field
    required this.membershipActive,
    required this.photoPath,
  });

  final String name;
  final String prn;
  final String phoneNumber; // Added property
  final bool membershipActive;
  final String photoPath;
}

class ScanOutcome {
  const ScanOutcome({
    required this.student,
    required this.isDuplicate,
    required this.recommendedDecision,
    required this.reason,
  });

  final Student student;
  final bool isDuplicate;
  final AttendanceDecision recommendedDecision;
  final String reason;
}

class DashboardStats {
  const DashboardStats({
    required this.totalStudents,
    required this.activeMembers,
    required this.servedToday,
    required this.pendingSync,
  });

  final int totalStudents;
  final int activeMembers;
  final int servedToday;
  final int pendingSync;
}

class AppController extends ChangeNotifier {
  AppController({
    FirebaseService? firebaseService,
    StudentService? studentService,
    AttendanceService? attendanceService,
    LocalStorageService? localStorageService,
    bool enableConnectivityMonitoring = true,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _studentService = studentService ?? const StudentService(),
        _attendanceService = attendanceService ?? const AttendanceService(),
        _localStorageService =
            localStorageService ?? const LocalStorageService(),
        _enableConnectivityMonitoring = enableConnectivityMonitoring;

  final FirebaseService _firebaseService;
  FirebaseService get firebaseService => _firebaseService;
  final StudentService _studentService;
  final AttendanceService _attendanceService;
  final LocalStorageService _localStorageService;
  final bool _enableConnectivityMonitoring;
  final Uuid _uuid = const Uuid();

  final List<Student> _students = <Student>[];
  final List<AttendanceLog> _attendanceLogs = <AttendanceLog>[];
  final Set<String> _duplicateKeys = <String>{};

  String _userRole = 'employee'; // Default
  String get userRole => _userRole;

StreamSubscription? _roleSubscription;

  void _startRoleListener(String uid) {
    _roleSubscription?.cancel();
    _roleSubscription = _firebaseService.userRoleStream(uid).listen((role) {
      if (_userRole != role) {
        _userRole = role;
        notifyListeners(); 
      }
    });
  }

// Update your disposeController to clean up the stream
Future<void> disposeController() async {
  await _roleSubscription?.cancel();
  await _connectivitySubscription?.cancel();
  dispose();
}

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _initialized = false;
  bool _busy = false;
  bool _isOnline = false;
  MealType _selectedMeal = MealType.lunch;
  DateTime? _lastSyncAttempt;
  String _syncStatus = 'Preparing local cache and Firebase backend.';

  List<Student> get students => 
    _studentService.sortStudents(_students.where((s) => !s.deleted));
  List<AttendanceLog> get attendanceLogs {
    final List<AttendanceLog> items = List<AttendanceLog>.from(_attendanceLogs)
      ..sort((AttendanceLog a, AttendanceLog b) => b.timestamp.compareTo(a.timestamp));
    return List<AttendanceLog>.unmodifiable(items);
  }

  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get isOnline => _isOnline;
  MealType get selectedMeal => _selectedMeal;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  String get syncStatus => _syncStatus;
  int get pendingSyncCount {
    final int studentPending =
        _students.where((Student student) => !student.syncedToCloud).length;
    final int attendancePending =
        _attendanceLogs.where((AttendanceLog log) => !log.syncedToCloud).length;
    return studentPending + attendancePending;
  }

Future<void> initialize() async {
    if (_initialized) {
      // Already initialized — but if a user just logged in, re-fetch their role
      if (_firebaseService.currentUser != null) {
        final String uid = _firebaseService.currentUser!.uid;
        _userRole = await _firebaseService.getUserRole(uid);
        _startRoleListener(uid);
        notifyListeners();
      }
      return;
    }

    await _restoreState();
    await _primeConnectivity();
    await _firebaseService.initialize();

    if (_firebaseService.currentUser != null) {
      final String uid = _firebaseService.currentUser!.uid;
      _userRole = await _firebaseService.getUserRole(uid); 
      _startRoleListener(uid);
    }

    _syncStatus = _firebaseService.statusMessage;
    if (_firebaseService.backendConfigured) {
      await _mergeRemoteState();
      if (_isOnline) {
        await syncPendingData();
        await _mergeRemoteState();
      }
    } else if (_students.isEmpty) {
      _seedDemoData();
      await _persistState();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
  if (_busy) return; // Prevent concurrent refreshes
  _busy = true;
  notifyListeners();

  try {
    await syncPendingData();
    await _mergeRemoteState();
  } catch (e) {
    _syncStatus = 'Refresh failed: $e';
  } finally {
    _busy = false;
    notifyListeners();
  }
}

  Future<void> _restoreState() async {
    final Map<String, dynamic> state = await _localStorageService.readState();
    final List<dynamic> studentMaps = state['students'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> attendanceMaps =
        state['attendanceLogs'] as List<dynamic>? ?? <dynamic>[];

    _students
      ..clear()
      ..addAll(
        studentMaps.map(
          (dynamic item) => Student.fromMap(item as Map<String, dynamic>),
        ),
      );

    _attendanceLogs
      ..clear()
      ..addAll(
        attendanceMaps.map(
          (dynamic item) => AttendanceLog.fromMap(item as Map<String, dynamic>),
        ),
      );

    _rebuildDuplicateKeys();
    _selectedMeal = MealType.values.byName(
      state['selectedMeal'] as String? ?? MealType.lunch.name,
    );
    _syncStatus = state['syncStatus'] as String? ?? _syncStatus;
    final String? lastSync = state['lastSyncAttempt'] as String?;
    _lastSyncAttempt = lastSync == null ? null : DateTime.parse(lastSync);
  }

  Future<void> _primeConnectivity() async {
    if (!_enableConnectivityMonitoring) {
      _isOnline = false;
      _syncStatus = 'Connectivity monitoring disabled for this session.';
      return;
    }

    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final bool nextOnline = !results.contains(ConnectivityResult.none);
          if (_isOnline == nextOnline) {
            return;
          }
          _isOnline = nextOnline;
          _syncStatus = _isOnline
              ? 'Connection detected. Firestore sync is available.'
              : 'Offline mode. Local cache and pending sync remain active.';
          notifyListeners();
          if (_isOnline && _firebaseService.backendConfigured) {
            unawaited(syncPendingData());
          }
        },
      );
    } catch (_) {
      _isOnline = false;
      _syncStatus = 'Connectivity plugin unavailable. Running with cached data only.';
    }
  }

  void setSelectedMeal(MealType value) {
    _selectedMeal = value;
    unawaited(_persistState());
    notifyListeners();
  }

  Future<Student> addStudent(StudentDraft draft) async {
    
    if (_students.any((s) => s.prn == draft.prn.trim() && !s.deleted)) {
      throw Exception('A student with this PRN already exists.');
    }

    _busy = true;
    notifyListeners();

    final DateTime now = DateTime.now();
    final String id = _buildStudentId(draft);
    String storedPhotoPath = '';
    if (draft.photoPath.isNotEmpty) {
      storedPhotoPath = await _localStorageService.persistStudentPhoto(
        studentId: id,
        sourcePath: draft.photoPath,
      );
    }

    final Student student = Student(
      id: id,
      qrPayload: id,
      name: draft.name.trim(),
      prn: draft.prn.trim(),
      phoneNumber: draft.phoneNumber.trim(), // Added mapping from draft
      membershipActive: draft.membershipActive,
      deleted: false,
      photoPath: storedPhotoPath,
      photoUrl: '',
      syncedToCloud: false,
      createdAt: now,
      updatedAt: now,
    );

    _students.removeWhere((Student item) => item.id == student.id);
    _students.add(student);
    await _persistState();
    if (_firebaseService.backendConfigured && _isOnline) {
      await syncPendingData();
    }
    _busy = false;
    notifyListeners();
    return student;
  }

  Future<void> setMembership({
    required String studentId,
    required bool active,
  }) async {
    final int index = _students.indexWhere((Student item) => item.id == studentId);
    if (index == -1) {
      return;
    }

    _students[index] = _students[index].copyWith(
      membershipActive: active,
      syncedToCloud: false,
      updatedAt: DateTime.now(),
    );
    await _persistState();
    if (_firebaseService.backendConfigured && _isOnline) {
      await syncPendingData();
    }
    notifyListeners();
  }

  Future<void> bulkSetMembership(
    Set<String> studentIds,
    bool active,
  ) async {
    for (final String studentId in studentIds) {
      final int index =
          _students.indexWhere((Student item) => item.id == studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(
          membershipActive: active,
          syncedToCloud: false,
          updatedAt: DateTime.now(),
        );
      }
    }
    await _persistState();
    if (_firebaseService.backendConfigured && _isOnline) {
      await syncPendingData();
    }
    notifyListeners();
  }

  Student? findStudentById(String id) {
    for (final Student student in _students) {
      if (student.id == id) {
        return student;
      }
    }
    return null;
  }

  Student? findStudentByQr(String qrPayload) => findStudentById(qrPayload.trim());

  ScanOutcome? inspectQrPayload(String qrPayload) {
    final Student? student = findStudentByQr(qrPayload);
    // If student is null or exists but is marked for deletion, deny entry.
    if (student == null || student.deleted) {
      return null; 
    }
    final DateTime now = DateTime.now();
    final String duplicateKey = _attendanceService.buildDuplicateKey(
      studentId: student.id,
      mealType: _selectedMeal,
      timestamp: now,
    );
    final bool isDuplicate = _duplicateKeys.contains(duplicateKey);
    final AttendanceDecision decision = student.membershipActive && !isDuplicate
        ? AttendanceDecision.allowed
        : AttendanceDecision.denied;
    final String reason = !student.membershipActive
        ? 'Membership inactive'
        : isDuplicate
            ? 'Already scanned for ${_selectedMeal.name} today'
            : 'Ready to allow entry';
    return ScanOutcome(
      student: student,
      isDuplicate: isDuplicate,
      recommendedDecision: decision,
      reason: reason,
    );
  }

  Future<AttendanceLog> recordAttendance({
    required Student student,
    required AttendanceDecision decision,
    required String reason,
  }) async {
    final DateTime now = DateTime.now();
    final AttendanceLog log = AttendanceLog(
      id: _uuid.v4(),
      studentId: student.id,
      studentName: student.name,
      mealType: _selectedMeal,
      decision: decision,
      reason: reason,
      timestamp: now,
      deviceId: 'android-local-device',
      syncedToCloud: false,
      dayKey: _attendanceService.buildDayKey(now),
    );
    _attendanceLogs.add(log);
    if (decision == AttendanceDecision.allowed) {
      _duplicateKeys.add(
        _attendanceService.buildDuplicateKey(
          studentId: student.id,
          mealType: _selectedMeal,
          timestamp: now,
        ),
      );
    }
    await _persistState();
    notifyListeners();
    if (_isOnline) {
      unawaited(syncPendingData());
    }
    return log;
  }

  DashboardStats dashboardStats() {
      final String today = _attendanceService.buildDayKey(DateTime.now());
      
      // MODIFIED: Only count logs that are synced to cloud (Global Data)
      final int globalServedToday = _attendanceLogs.where((AttendanceLog log) {
        return log.dayKey == today &&
            log.mealType == _selectedMeal &&
            log.decision == AttendanceDecision.allowed &&
            log.syncedToCloud == true; // <--- This ensures only global data is counted
      }).length;

      return DashboardStats(
        totalStudents: _students.length,
        activeMembers:
            _students.where((Student student) => student.membershipActive).length,
        servedToday: globalServedToday, // Passing the global count
        pendingSync: pendingSyncCount,
      );
    }

  List<Student> searchStudents(String query) {
    return _studentService.search(_students, query);
  }

  List<AttendanceLog> logsForStudent(String studentId) {
    final List<AttendanceLog> result = _attendanceLogs
        .where((AttendanceLog log) => log.studentId == studentId)
        .toList()
      ..sort((AttendanceLog a, AttendanceLog b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<void> syncPendingData() async {
    if (!_firebaseService.backendConfigured) {
      _syncStatus = _firebaseService.statusMessage;
      await _persistState();
      notifyListeners();
      return;
    }

    final List<Student> pendingStudents = _students
        .where((Student student) => !student.syncedToCloud)
        .toList();
    final List<AttendanceLog> pendingLogs = _attendanceLogs
        .where((AttendanceLog log) => !log.syncedToCloud)
        .toList();
    _lastSyncAttempt = DateTime.now();

    if (pendingStudents.isEmpty && pendingLogs.isEmpty) {
      _syncStatus = 'Cloud state is up to date.';
      await _persistState();
      notifyListeners();
      return;
    }

    final SyncResult result = await _firebaseService.syncPendingAttendance(
      pendingStudents: pendingStudents,
      pendingLogs: pendingLogs,
    );

    for (final StudentSyncUpdate update in result.studentUpdates) {
      final int index =
          _students.indexWhere((Student student) => student.id == update.studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(
          photoUrl: update.photoUrl,
          syncedToCloud: update.synced,
        );
      }
    }

    for (final AttendanceSyncUpdate update in result.attendanceUpdates) {
      final int index =
          _attendanceLogs.indexWhere((AttendanceLog log) => log.id == update.logId);
      if (index != -1) {
        _attendanceLogs[index] = _attendanceLogs[index].copyWith(
          syncedToCloud: update.synced,
          decision: update.correctedDecision,
          reason: update.correctedReason,
        );
      }
    }

    _rebuildDuplicateKeys();
    _syncStatus = result.message;
    await _persistState();
    notifyListeners();
  }

Future<void> _mergeRemoteState() async {
    try {
      final List<Student> remoteStudents = await _firebaseService.fetchStudents();
      final List<AttendanceLog> remoteLogs = await _firebaseService.fetchAttendanceLogs();

      // --- PRODUCTION SYNC: CROSS-DEVICE DELETION ---
      final Set<String> remoteIds = remoteStudents.map((s) => s.id).toSet();
      
      // Identify students that exist locally but are GONE from the Cloud
      // We only delete them locally if they were previously synced (syncedToCloud == true)
      final List<Student> deletedOnOtherDevice = _students.where((local) => 
          local.syncedToCloud && !remoteIds.contains(local.id)).toList();

      for (var student in deletedOnOtherDevice) {
        if (student.photoPath.isNotEmpty) {
          final file = File(student.photoPath);
          if (await file.exists()) await file.delete();
        }
        _students.removeWhere((s) => s.id == student.id);
      }

      // Cleanup logs for students no longer in the system
      _attendanceLogs.removeWhere((log) => 
          log.syncedToCloud && !remoteIds.contains(log.studentId));

      final Map<String, Student> mergedStudents = {
        for (final Student student in _students) 
          if (!student.syncedToCloud || remoteIds.contains(student.id)) student.id: student,
      };

      // --- PHOTO SYNC WITH PERMANENT PATHS ---
      final Directory root = await _localStorageService.appDirectory();
      final String photosDirPath = '${root.path}/photos';
      await Directory(photosDirPath).create(recursive: true);

      for (final Student remote in remoteStudents) {
        final Student? local = mergedStudents[remote.id];
        Student studentToProcess = remote;

        if (remote.photoUrl.isNotEmpty) {
          final String localPath = '$photosDirPath/${remote.id}.jpg';
          final File localFile = File(localPath);

          // Download only if missing
          if (!localFile.existsSync()) {
            try {
              await _firebaseService.downloadStudentPhoto(remote.photoUrl, localPath);
              studentToProcess = remote.copyWith(photoPath: localPath);
            } catch (e) {
              debugPrint('Photo sync failed for ${remote.name}: $e');
              // Crucial: Fallback to the remote object without the local path 
              // so the record is still updated even if the photo fails.
              studentToProcess = remote; 
            }
          } else {
            studentToProcess = remote.copyWith(photoPath: localPath);
          }
        }

        // Logic: Remote wins if it's newer than local
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          mergedStudents[remote.id] = studentToProcess;
        }
      }

      // Standard Log Merge
      final Map<String, AttendanceLog> mergedLogs = {
        for (final AttendanceLog log in _attendanceLogs) log.id: log,
      };
      for (final AttendanceLog remote in remoteLogs) {
        final AttendanceLog? local = mergedLogs[remote.id];
        if (local == null || remote.timestamp.isAfter(local.timestamp)) {
          mergedLogs[remote.id] = remote;
        }
      }

      _students..clear()..addAll(mergedStudents.values);
      _attendanceLogs..clear()..addAll(mergedLogs.values);
      
      _rebuildDuplicateKeys();
      await _persistState();
    } catch (e) {
      _syncStatus = 'Auto-sync failed: $e';
    }
  }

  void _rebuildDuplicateKeys() {
  _duplicateKeys.clear();
  final String today = _attendanceService.buildDayKey(DateTime.now());
  
  // Optimization: Iterate backwards or filter first to avoid processing 
  // years of old logs for a simple daily duplicate check.
  for (final AttendanceLog log in _attendanceLogs.reversed) {
    // If we hit logs from yesterday, we can stop (assuming logs are sorted)
    if (log.dayKey != today) continue; 
    
    if (log.decision == AttendanceDecision.allowed) {
      final key = _attendanceService.buildDuplicateKey(
        studentId: log.studentId,
        mealType: log.mealType,
        timestamp: log.timestamp,
      );
      _duplicateKeys.add(key);
    }
  }
}

  Future<void> _persistState() async {
    await _localStorageService.writeState(
      <String, dynamic>{
        'students': _students.map((Student student) => student.toMap()).toList(),
        'attendanceLogs':
            _attendanceLogs.map((AttendanceLog log) => log.toMap()).toList(),
        'selectedMeal': _selectedMeal.name,
        'syncStatus': _syncStatus,
        'lastSyncAttempt': _lastSyncAttempt?.toIso8601String(),
      },
    );
  }

  String _buildStudentId(StudentDraft draft) {
  final String cleanName = draft.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  final String cleanPrn = draft.prn.trim().toLowerCase();
  
  return '${cleanPrn}_$cleanName';
}

Future<void> deleteStudent(String studentId) async {
    _busy = true;
    notifyListeners();

    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;

    final student = _students[index];

    // 1. Delete local photo file
    if (student.photoPath.isNotEmpty) {
      final file = File(student.photoPath);
      if (await file.exists()) await file.delete();
    }

    // 2. Remove from local memory lists entirely
    _students.removeAt(index);
    _attendanceLogs.removeWhere((log) => log.studentId == studentId);

    // 3. Persist the now-shorter lists to local storage
    await _persistState();

    // 4. Wipe from Firebase
    if (_isOnline && _firebaseService.backendConfigured) {
      try {
        await _firebaseService.deleteStudentData(studentId, student.photoUrl);
      } catch (e) {
        debugPrint('Cloud deletion failed: $e');
        // Note: In a production app, you might want to queue this 
        // to retry later if the user is currently offline.
      }
    }

    _busy = false;
    notifyListeners();
  }

  void _seedDemoData() {
    final DateTime now = DateTime.now();
    _students
      ..clear()
      ..addAll(
        <Student>[
          Student(
            id: '2023001-BTECHCSE-2-AAAA01',
            qrPayload: '2023001-BTECHCSE-2-AAAA01',
            name: 'Aarav Patil',
            prn: '2023001',
            phoneNumber: '', // Added empty default for demo
            membershipActive: true,
            deleted: false,
            photoPath: '',
            photoUrl: '',
            syncedToCloud: false,
            createdAt: now,
            updatedAt: now,
          ),
          Student(
            id: '2023002-BSCIT-1-BBBB02',
            qrPayload: '2023002-BSCIT-1-BBBB02',
            name: 'Isha Deshmukh',
            prn: '2023002',
            phoneNumber: '', // Added empty default for demo
            membershipActive: false,
            deleted: false,
            photoPath: '',
            photoUrl: '',
            syncedToCloud: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
  }
}