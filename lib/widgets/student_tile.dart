import 'dart:io';

import 'package:flutter/material.dart';

import '../models/student.dart';

class StudentTile extends StatelessWidget {
  const StudentTile({
    required this.student,
    this.trailing,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final Student student;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color badgeColor =
        student.membershipActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final ImageProvider<Object>? avatarImage = _avatarImage(student);

    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFE6FFFB) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFCCFBF1),
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Text(
                  student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                )
              : null,
        ),
        title: Text(
          student.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('PRN: ${student.prn}'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Badge(
                    label: student.subtitle,
                    color: const Color(0xFF0F766E),
                  ),
                  _Badge(
                    label: student.membershipActive ? 'Active' : 'Inactive',
                    color: badgeColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  ImageProvider<Object>? _avatarImage(Student student) {
    if (student.photoPath.isNotEmpty) {
      return FileImage(File(student.photoPath));
    }
    if (student.photoUrl.isNotEmpty) {
      return NetworkImage(student.photoUrl);
    }
    return null;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
