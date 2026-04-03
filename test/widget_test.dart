import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/models/attendance.dart';
import 'package:mess_app/models/student.dart';
import 'package:mess_app/services/attendance_service.dart';
import 'package:mess_app/services/student_service.dart';

void main() {
  test('student search matches by name and prn', () {
    const StudentService service = StudentService();
    final DateTime now = DateTime(2026, 3, 28);
    final List<Student> students = <Student>[
      Student(
        id: '1',
        qrPayload: '1',
        name: 'Aarav Patil',
        prn: '2023001',
        phoneNumber: '1234567890',
        membershipActive: true,
        deleted: false,
        photoPath: '',
        photoUrl: '',
        syncedToCloud: false,
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: '2',
        qrPayload: '2',
        name: 'Isha Deshmukh',
        prn: '2023002',
        phoneNumber: '0987654321',
        membershipActive: false,
        deleted: false,
        photoPath: '',
        photoUrl: '',
        syncedToCloud: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    expect(service.search(students, 'aarav').single.name, 'Aarav Patil');
    expect(service.search(students, '2023002').single.name, 'Isha Deshmukh');
  });

  test('attendance duplicate key is stable for same day and meal', () {
    const AttendanceService service = AttendanceService();
    final DateTime timestamp = DateTime(2026, 3, 28, 13, 30);

    final String first = service.buildDuplicateKey(
      studentId: 'student-1',
      mealType: MealType.lunch,
      timestamp: timestamp,
    );
    final String second = service.buildDuplicateKey(
      studentId: 'student-1',
      mealType: MealType.lunch,
      timestamp: DateTime(2026, 3, 28, 13, 45),
    );

    expect(first, second);
  });
}
