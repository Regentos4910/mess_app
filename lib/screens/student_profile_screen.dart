import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

        if (student == null || student.deleted) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
            body: const Center(child: Text('Record no longer exists.', style: TextStyle(color: Colors.grey))),
          );
        }

        final List<AttendanceLog> logs = controller.logsForStudent(student.id);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: true,
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            actions: [
              // ONLY SHOW DELETE TO ADMINS
              if (controller.userRole == 'admin' || controller.userRole == 'superuser')
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _confirmDeletion(context, student),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // 1. Vibrant Identity Section
                _buildIdentityHeader(student),
                
                const SizedBox(height: 32),

                // 2. Actionable Membership Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: controller.userRole == 'admin' || controller.userRole == 'superuser'
                      ? _buildMembershipAction(student) 
                      : _buildMembershipStatusOnly(student), // Show status if not admin
                ),

                const SizedBox(height: 32),

                // 3. Circular QR Section
                _buildQrSection(student),

                const SizedBox(height: 40),

                // 4. Clean Activity Timeline
                _buildActivitySection(logs),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityHeader(Student student) {
    final bool isActive = student.membershipActive;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? Colors.blueAccent.withAlpha(51) : Colors.grey.shade200, width: 2),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade50,
            backgroundImage: student.photoPath.isNotEmpty && File(student.photoPath).existsSync()
                ? FileImage(File(student.photoPath))
                : null,
            child: student.photoPath.isEmpty 
                ? Text(student.name[0].toUpperCase(), 
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.blueAccent)) 
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(student.name, 
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('PRN ${student.prn}', 
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        
        // --- PHONE NUMBER DISPLAY SECTION ---
        if (student.phoneNumber.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android_rounded, size: 14, color: Colors.blueAccent.withAlpha(178)),
                const SizedBox(width: 6),
                Text(
                  student.phoneNumber, 
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey.shade700, 
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMembershipStatusOnly(Student student) {
  final bool active = student.membershipActive;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(active ? Icons.verified_user_rounded : Icons.info_outline_rounded, 
            size: 20, color: active ? Colors.tealAccent.shade700 : Colors.orangeAccent),
        const SizedBox(width: 10),
        Text(
          active ? 'Membership Active' : 'Membership Inactive',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: active ? Colors.tealAccent.shade700 : Colors.orangeAccent.shade700,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMembershipAction(Student student) {
    final bool active = student.membershipActive;
    return InkWell(
      onTap: () => controller.setMembership(studentId: student.id, active: !active),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? Colors.grey.shade50 : Colors.tealAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.grey.shade200 : Colors.tealAccent.withAlpha(128)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? Icons.block_rounded : Icons.check_circle_rounded, 
                size: 20, color: active ? Colors.orangeAccent : Colors.tealAccent.shade700),
            const SizedBox(width: 10),
            Text(
              active ? 'Revoke Access' : 'Authorize Membership',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: active ? Colors.orangeAccent.shade700 : Colors.tealAccent.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(Student student) {
    return Column(
      children: [
        Text('DIGITAL ACCESS KEY', 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: QrImageView(
            data: student.qrPayload,
            size: 170,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Text(student.id, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildActivitySection(List<AttendanceLog> logs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meal History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No scans recorded yet', style: TextStyle(color: Colors.grey.shade400)),
            )),
          ...logs.map((log) => _buildActivityTile(log)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(AttendanceLog log) {
    final bool allowed = log.decision == AttendanceDecision.allowed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: allowed ? Colors.greenAccent.withAlpha(25) : Colors.redAccent.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allowed ? Icons.done_rounded : Icons.close_rounded,
              size: 18,
              color: allowed ? Colors.green.shade700 : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.mealLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('MMM dd • hh:mm a').format(log.timestamp), 
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(allowed ? 'ALLOWED' : 'DENIED', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: allowed ? Colors.green.shade700 : Colors.redAccent)),
        ],
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context, Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Student?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to permanently delete ${student.name}? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteStudent(student.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}