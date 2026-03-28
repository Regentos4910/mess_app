import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/attendance.dart';
import '../models/student.dart';
import '../services/app_controller.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    required this.controller,
    required this.studentId,
    super.key,
  });

  static const String routeName = '/student-profile';
  final AppController controller;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final Student? student = controller.findStudentById(studentId);
        if (student == null) {
          return const Scaffold(
            body: Center(child: Text('Student not found.')),
          );
        }

        final List<AttendanceLog> logs = controller.logsForStudent(student.id);

        return Scaffold(
          appBar: AppBar(title: const Text('Student Profile')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFFCCFBF1),
                        backgroundImage: student.photoPath.isNotEmpty
                            ? FileImage(File(student.photoPath))
                            : null,
                        child: student.photoPath.isEmpty
                            ? Text(
                                student.name[0].toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F766E),
                                    ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('PRN: ${student.prn}'),
                      Text(student.subtitle),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => controller.setMembership(
                          studentId: student.id,
                          active: !student.membershipActive,
                        ),
                        child: Text(
                          student.membershipActive
                              ? 'Deactivate Membership'
                              : 'Activate Membership',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Student QR',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: student.qrPayload,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      SelectableText(student.qrPayload),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attendance History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No attendance recorded yet.'),
                  ),
                ),
              ...logs.map(
                (AttendanceLog log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      title: Text(log.mealLabel),
                      subtitle: Text('${log.timestamp}\n${log.reason}'),
                      trailing: Icon(
                        log.decision == AttendanceDecision.allowed
                            ? Icons.check_circle
                            : Icons.block,
                        color: log.decision == AttendanceDecision.allowed
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
