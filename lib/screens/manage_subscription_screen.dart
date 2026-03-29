import 'dart:io';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/app_controller.dart';
import 'student_profile_screen.dart'; // To navigate to profile on tap

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

  Future<bool> _confirmDelete(int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Delete $count Students?', 
                style: const TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('This will permanently remove records from the cloud and device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), 
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', 
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;
  }

  Future<void> _handleBulkDelete() async {
    final confirmed = await _confirmDelete(_selectedIds.length);
    if (!confirmed) return;
    for (final id in List<String>.from(_selectedIds)) {
      await widget.controller.deleteStudent(id);
    }
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final List<Student> students = widget.controller.searchStudents(_searchController.text);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: false,
            title: Text(
              _selectedIds.isEmpty ? 'Directory' : '${_selectedIds.length} Selected',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            actions: [
              if (_selectedIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.select_all_rounded, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == students.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(students.map((s) => s.id));
                      }
                    });
                  },
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              // Compact Search Area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search Name or PRN...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40), 
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Student List with Differentiated Tiling
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isSelected = _selectedIds.contains(student.id);
                    
                    // Visual differentiation colors
                    final Color tileColor = index % 2 == 0 
                        ? const Color(0xFFF8FAFC) 
                        : const Color(0xFFF0F9FF);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : tileColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.blueAccent.withOpacity(0.3) 
                              : Colors.black.withOpacity(0.03),
                        ),
                      ),
                      child: ListTile(
                        // FIX: Long press to select, tap to view profile
                        // This prevents the "weird pop up" conflict and adds professional UX
                        onTap: () {
                          if (_selectedIds.isNotEmpty) {
                            _toggleSelection(student.id);
                          } else {
                            Navigator.pushNamed(
                              context, 
                              StudentProfileScreen.routeName, 
                              arguments: student.id
                            );
                          }
                        },
                        onLongPress: () => _toggleSelection(student.id),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: student.photoPath.isNotEmpty && File(student.photoPath).existsSync()
                              ? FileImage(File(student.photoPath))
                              : null,
                          child: student.photoPath.isEmpty 
                              ? const Icon(Icons.person, color: Colors.blueAccent) 
                              : null,
                        ),
                        title: Text(
                          student.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              _smallPill(student.prn, Colors.blueAccent),
                              const SizedBox(width: 6),
                              _smallPill(
                                student.membershipActive ? 'ACTIVE' : 'INACTIVE', 
                                student.membershipActive ? Colors.green.shade700 : Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle_rounded, color: Colors.blueAccent)
                          : Switch.adaptive(
                              value: student.membershipActive,
                              activeColor: Colors.blueAccent,
                              onChanged: (val) => widget.controller.setMembership(
                                studentId: student.id, 
                                active: val,
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _selectedIds.isEmpty ? null : _buildFloatingActionPill(),
        );
      },
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Widget _smallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, 
          fontWeight: FontWeight.w900, 
          color: color, 
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFloatingActionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillAction(Icons.verified_rounded, 'Activate', Colors.greenAccent, () => _bulkUpdate(active: true)),
          const SizedBox(
            height: 20,
            child: VerticalDivider(color: Colors.white24, thickness: 1, width: 20),
          ),
          _pillAction(Icons.block_rounded, 'Block', Colors.orangeAccent, () => _bulkUpdate(active: false)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            onPressed: _handleBulkDelete,
          ),
        ],
      ),
    );
  }

  Widget _pillAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdate({required bool active}) async {
    await widget.controller.bulkSetMembership(_selectedIds, active);
    setState(() => _selectedIds.clear());
  }
}