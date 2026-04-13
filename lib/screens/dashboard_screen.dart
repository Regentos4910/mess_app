import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mess_app/screens/login_screen.dart';

import '../models/attendance.dart';
import '../models/student.dart';
import '../services/app_controller.dart';
import '../widgets/action_card.dart';
import 'add_student_screen.dart';
import 'attendance_history_screen.dart';
import 'manage_subscription_screen.dart';
import 'scan_screen.dart';
import 'student_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/dashboard';
  final AppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? Any unsynced data will remain on this device.',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', 
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show a snackbar or overlay if the network is slow
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signing out...'), duration: Duration(seconds: 1)),
      );

      await widget.controller.firebaseService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName, 
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final DashboardStats stats = widget.controller.dashboardStats();
        
        // Check if user is Admin
        final bool isAdmin = widget.controller.userRole == 'admin' || widget.controller.userRole == 'superuser';
        final bool isSuperUser = widget.controller.userRole == 'superuser';

        final List<Student> filteredStudents = widget.controller
            .searchStudents(_searchQuery)
            .take(isAdmin ? 10 : 5)
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mess Manager',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 20, 
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  widget.controller.firebaseService.currentUser?.email ?? 'Not Signed In',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              if (isSuperUser)
                IconButton(
                  onPressed: () => Navigator.of(context).pushNamed('/export-data'),
                  icon: const Icon(
                    Icons.description_rounded, // Use the spreadsheet-style icon
                    color: Colors.green,
                  ),
                  tooltip: 'Export Data',
                ),
              // Updated Sync/Refresh Button
              IconButton(
                onPressed: widget.controller.busy
                    ? null // Disable while refresh is in progress
                    : () async {
                        await widget.controller.refresh();
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data refreshed'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                icon: widget.controller.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      )
                    : Icon(
                        stats.pendingSync > 0
                            ? Icons.sync_problem_rounded
                            : Icons.refresh_rounded,
                        color: stats.pendingSync > 0 ? Colors.redAccent : Colors.blueAccent,
                      ),
              ),
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.orangeAccent),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      _buildMealSelectorRow(),
                      const SizedBox(height: 16),
                      // ONLY SHOW STATS TO ADMIN
                      if (isAdmin) _buildCompactStats(stats),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    ActionCard(
                      title: 'Scan QR',
                      subtitle: 'Entry',
                      icon: Icons.qr_code_scanner_rounded,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.of(context).pushNamed(ScanScreen.routeName),
                    ),
                    ActionCard(
                      title: 'Add Student',
                      subtitle: 'New',
                      icon: Icons.person_add_alt_1_rounded,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.of(context).pushNamed(AddStudentScreen.routeName),
                    ),
                    if (isAdmin)
                      ActionCard(
                        title: 'History',
                        subtitle: 'Logs',
                        icon: Icons.history_rounded,
                        color: Colors.redAccent,
                        onTap: () => Navigator.of(context).pushNamed(AttendanceHistoryScreen.routeName),
                      ),
                    // ONLY SHOW DIRECTORY TO ADMIN
                    if (isAdmin)
                      ActionCard(
                        title: 'Directory',
                        subtitle: 'Manage',
                        icon: Icons.folder_shared_rounded,
                        color: Colors.tealAccent.shade700,
                        onTap: () => Navigator.of(context).pushNamed(ManageSubscriptionScreen.routeName),
                      ),
                  ],
                ),
              ),

              // 3. Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: _buildSearchBar(),
                ),
              ),

              // 4. Student List
              filteredStudents.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No students found', style: TextStyle(color: Colors.grey)),
                      )),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStudentTile(filteredStudents[index]),
                        childCount: filteredStudents.length,
                      ),
                    ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealSelectorRow() {
    final List<String> mealLabels = ['Breakfast', 'Lunch', 'Dinner'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(40), // Circular borders
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MealType>(
          value: widget.controller.selectedMeal,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          items: MealType.values.map((m) => DropdownMenuItem(value: m, child: Text(mealLabels[m.index]))).toList(),
          onChanged: (val) {
            if (val != null) widget.controller.setSelectedMeal(val);
          },
        ),
      ),
    );
  }

  Widget _buildCompactStats(DashboardStats stats) {
    return Row(
      children: [
        _statItem('Total Students', '${stats.totalStudents}', Colors.blueAccent),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        _statItem('Served Today', '${stats.servedToday}', Colors.redAccent),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search Name or PRN...',
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40), // Circular borders
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed(StudentProfileScreen.routeName, arguments: student.id),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.grey.shade50,
        leading: ClipRRect(
  borderRadius: BorderRadius.circular(25),
  child: SizedBox(
    width: 50,
    height: 50,
    child: student.photoPath.isNotEmpty && File(student.photoPath).existsSync()
        ? Image.file(File(student.photoPath), fit: BoxFit.cover)
        : (student.photoUrl.isNotEmpty 
            ? CachedNetworkImage(
                imageUrl: student.photoUrl,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => const Icon(Icons.person),
                fit: BoxFit.cover,
              )
            : const Icon(Icons.person, color: Colors.blueAccent)),
  ),
),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(student.prn, style: const TextStyle(fontSize: 12)),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: widget.controller.userRole == 'admin' 
              ? Colors.blueAccent.withAlpha(180) 
              : Colors.grey.shade300,
        ),
      ),
    );
  }
}