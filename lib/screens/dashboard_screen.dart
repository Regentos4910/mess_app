import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../services/app_controller.dart';
import '../widgets/action_card.dart';
import '../widgets/stats_card.dart';
import 'add_student_screen.dart';
import 'attendance_history_screen.dart';
import 'manage_subscription_screen.dart';
import 'scan_screen.dart';
import 'student_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/dashboard';
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final DashboardStats stats = controller.dashboardStats();
        final List<String> mealLabels = <String>['Breakfast', 'Lunch', 'Dinner'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mess Dashboard'),
            actions: <Widget>[
              IconButton(
                onPressed: controller.syncPendingData,
                icon: const Icon(Icons.sync),
                tooltip: 'Sync pending data',
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF042F2E), Color(0xFF0F766E)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Current Mode',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanning for ${mealLabels[controller.selectedMeal.index]}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MealType>(
                        initialValue: controller.selectedMeal,
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(
                          labelText: 'Meal session',
                          fillColor: Colors.white,
                        ),
                        items: MealType.values
                            .map(
                              (MealType meal) => DropdownMenuItem<MealType>(
                                value: meal,
                                child: Text(mealLabels[meal.index]),
                              ),
                            )
                            .toList(),
                        onChanged: (MealType? value) {
                          if (value != null) {
                            controller.setSelectedMeal(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.syncStatus,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 132,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: StatsCard(
                          label: 'Students',
                          value: '${stats.totalStudents}',
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          label: 'Active',
                          value: '${stats.activeMembers}',
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          label: 'Served Today',
                          value: '${stats.servedToday}',
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          label: 'Pending Sync',
                          value: '${stats.pendingSync}',
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.08,
                  children: <Widget>[
                    ActionCard(
                      title: 'Scan Student',
                      subtitle: 'Continuous QR scanning with allow or deny flow',
                      icon: Icons.qr_code_scanner,
                      onTap: () =>
                          Navigator.of(context).pushNamed(ScanScreen.routeName),
                    ),
                    ActionCard(
                      title: 'Add Student',
                      subtitle: 'Capture a photo and generate local QR instantly',
                      icon: Icons.person_add_alt_1,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AddStudentScreen.routeName),
                    ),
                    ActionCard(
                      title: 'Attendance History',
                      subtitle: 'Review allowed and denied entries per meal',
                      icon: Icons.history,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AttendanceHistoryScreen.routeName),
                    ),
                    ActionCard(
                      title: 'Subscriptions',
                      subtitle: 'Activate or deactivate membership in bulk',
                      icon: Icons.verified_user,
                      onTap: () => Navigator.of(context)
                          .pushNamed(ManageSubscriptionScreen.routeName),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                ...controller.students.take(5).map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(student.name),
                          subtitle: Text('${student.prn} • ${student.subtitle}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pushNamed(
                            StudentProfileScreen.routeName,
                            arguments: student.id,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
