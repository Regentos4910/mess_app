import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../services/app_controller.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/attendance-history';
  final AppController controller;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  MealType? _mealFilter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final List<AttendanceLog> logs = widget.controller.attendanceLogs.where(
          (AttendanceLog log) {
            if (_mealFilter == null) {
              return true;
            }
            return log.mealType == _mealFilter;
          },
        ).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Attendance History')),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: DropdownButtonFormField<MealType?>(
                  initialValue: _mealFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by meal',
                  ),
                  items: <DropdownMenuItem<MealType?>>[
                    const DropdownMenuItem<MealType?>(
                      value: null,
                      child: Text('All meals'),
                    ),
                    ...MealType.values.map(
                      (MealType meal) => DropdownMenuItem<MealType?>(
                        value: meal,
                        child: Text(_labelForMeal(meal)),
                      ),
                    ),
                  ],
                  onChanged: (MealType? value) {
                    setState(() {
                      _mealFilter = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('No attendance logs yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final AttendanceLog log = logs[index];
                          final bool allowed =
                              log.decision == AttendanceDecision.allowed;
                          return Card(
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(log.studentName),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${log.mealLabel} • ${log.timestamp}'
                                  '\n${log.reason.isEmpty ? 'No note' : log.reason}',
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    allowed ? Icons.check_circle : Icons.block,
                                    color: allowed
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB91C1C),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    log.syncedToCloud ? 'Synced' : 'Pending',
                                    style: TextStyle(
                                      color: log.syncedToCloud
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF92400E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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

  String _labelForMeal(MealType meal) {
    return switch (meal) {
      MealType.breakfast => 'Breakfast',
      MealType.lunch => 'Lunch',
      MealType.dinner => 'Dinner',
    };
  }
}
