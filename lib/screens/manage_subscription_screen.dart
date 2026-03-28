import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/app_controller.dart';
import '../widgets/student_tile.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/subscriptions';
  final AppController controller;

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final List<Student> students =
            widget.controller.searchStudents(_searchController.text);

        return Scaffold(
          appBar: AppBar(title: const Text('Manage Subscription')),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search by name, PRN, course, division',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _bulkUpdate(active: true),
                        child: const Text('Bulk Activate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _bulkUpdate(active: false),
                        child: const Text('Bulk Deactivate'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final Student student = students[index];
                    return StudentTile(
                      student: student,
                      selected: _selectedIds.contains(student.id),
                      onTap: () {
                        setState(() {
                          if (_selectedIds.contains(student.id)) {
                            _selectedIds.remove(student.id);
                          } else {
                            _selectedIds.add(student.id);
                          }
                        });
                      },
                      trailing: Switch(
                        value: student.membershipActive,
                        onChanged: (bool value) {
                          widget.controller.setMembership(
                            studentId: student.id,
                            active: value,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _bulkUpdate({required bool active}) async {
    await widget.controller.bulkSetMembership(_selectedIds, active);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(active ? 'Memberships activated.' : 'Memberships deactivated.'),
      ),
    );
  }
}
