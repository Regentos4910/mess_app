import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mess_app/services/excel_service.dart';
import 'package:mess_app/services/pdf_service.dart'; // Ensure you create this
import '../models/attendance.dart';
import '../services/app_controller.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({required this.controller, super.key});

  static const String routeName = '/export-data';
  final AppController controller;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  MealType? _selectedMealFilter;
  bool _onlyAllowedEntries = true;
  String _sortBy = 'Timestamp';
  bool _isGenerating = false;

  static const Color accentBlue = Colors.blueAccent;
  static const Color textMain = Color(0xFF1A1C1E);
  static const Color textSub = Color(0xFF6C757D);

  // Unified logic for triggering reports
  // Inside _ExportScreenState class...

void _processReport(bool isPdf) async {
  if (_isGenerating) return;

  setState(() => _isGenerating = true);

  try {
    // 1. Fetch data
    List<AttendanceLog> allLogs = widget.controller.attendanceLogs;

    // 2. Build filtered list
    List<AttendanceLog> filteredLogs = allLogs.where((log) {
      final isAfterStart = log.timestamp.isAfter(_startDate.subtract(const Duration(seconds: 1)));
      final isBeforeEnd = log.timestamp.isBefore(_endDate.add(const Duration(days: 1)));
      final matchesMeal = _selectedMealFilter == null || log.mealType == _selectedMealFilter;
      final matchesStatus = !_onlyAllowedEntries || log.decision == AttendanceDecision.allowed;

      return isAfterStart && isBeforeEnd && matchesMeal && matchesStatus;
    }).toList();

    // 3. Validation
    if (filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records found for these filters.')),
      );
      setState(() => _isGenerating = false);
      return;
    }

    // 4. Sorting
    if (_sortBy == 'Student Name') {
      filteredLogs.sort((a, b) => a.studentName.compareTo(b.studentName));
    } else if (_sortBy == 'PRN') {
      filteredLogs.sort((a, b) => a.studentId.compareTo(b.studentId));
    }

    String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String fileName = "Mess_Report_$formattedDate";

    // 5. Action
    if (isPdf) {
      await PdfService.generateAndShare(
        logs: allLogs, 
        filteredLogs: filteredLogs, 
        fileName: fileName,
        start: _startDate,
        end: _endDate,
        mealFilter: _selectedMealFilter?.name.toUpperCase() ?? "ALL MEALS",
      );
    } else {
      await ExcelService.generateAndShare(
        logs: allLogs, 
        filteredLogs: filteredLogs, 
        fileName: fileName,
      );
    }
  } catch (e) {
    debugPrint("Export Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report Generation Failed: $e')),
    );
  } finally {
    // THIS PART IS CRITICAL: Stops the loading state regardless of success or failure
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }
}

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: accentBlue, onSurface: textMain),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textMain,
        title: const Text('Export Center', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select format and customize your report.', 
                    style: TextStyle(color: textSub, fontSize: 15)),
                  const SizedBox(height: 32),

                  _buildLabel('TIMEFRAME'),
                  _buildDateCard(),
                  const SizedBox(height: 12),
                  _buildQuickPresets(),

                  const SizedBox(height: 32),
                  _buildLabel('MEAL FILTER'),
                  _buildMealSelection(),

                  const SizedBox(height: 32),
                  _buildLabel('PREFERENCES'),
                  _buildPreferencesCard(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textSub, letterSpacing: 1.2)),
  );

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: accentBlue.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          _dateField('From', _startDate, () => _selectDate(true)),
          Container(height: 40, width: 1, color: Colors.grey.shade100),
          _dateField('To', _endDate, () => _selectDate(false)),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(DateFormat('MMM dd, yyyy').format(date), 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textMain)),
        ],
      ),
    ),
  );

  Widget _buildQuickPresets() {
    final presets = {'Today': 0, 'Week': 7, 'Month': 30};
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ActionChip(
          label: Text(e.key),
          onPressed: () => setState(() {
            _endDate = DateTime.now();
            _startDate = DateTime.now().subtract(Duration(days: e.value));
          }),
          backgroundColor: Colors.white,
          elevation: 0,
          labelStyle: const TextStyle(color: accentBlue, fontSize: 12, fontWeight: FontWeight.bold),
          shape: StadiumBorder(side: BorderSide(color: accentBlue.withAlpha(10))),
        ),
      )).toList(),
    );
  }

  Widget _buildMealSelection() => Wrap(
    spacing: 12,
    children: [
      _mealChip('All', null),
      _mealChip('Breakfast', MealType.breakfast),
      _mealChip('Lunch', MealType.lunch),
      _mealChip('Dinner', MealType.dinner),
    ],
  );

  Widget _mealChip(String label, MealType? type) {
    final isSelected = _selectedMealFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedMealFilter = type),
      selectedColor: accentBlue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : textMain, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? accentBlue : Colors.grey.shade200)),
    );
  }

  Widget _buildPreferencesCard() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
    child: Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          title: const Text('Verified Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: const Text('Exclude denied entries', style: TextStyle(fontSize: 12)),
          value: _onlyAllowedEntries,
          activeThumbColor: accentBlue,
          onChanged: (v) => setState(() => _onlyAllowedEntries = v),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          title: const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          trailing: DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: accentBlue),
            style: const TextStyle(fontWeight: FontWeight.bold, color: accentBlue, fontSize: 14),
            items: ['Timestamp', 'Student Name', 'PRN'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomAction() => Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
    decoration: BoxDecoration(
      color: Colors.white, 
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, -5))]
    ),
    child: Row(
      children: [
        Expanded(
          child: _formatButton(
            label: 'Excel', 
            icon: Icons.table_chart_rounded, 
            color: Colors.teal.shade600, 
            onTap: () => _processReport(false)
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _formatButton(
            label: 'PDF', 
            icon: Icons.picture_as_pdf_rounded, 
            color: accentBlue, 
            onTap: () => _processReport(true)
          ),
        ),
      ],
    ),
  );

  Widget _formatButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        icon: _isGenerating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}