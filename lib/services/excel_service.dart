import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance.dart';

class ExcelService {
  static Future<void> generateAndShare({
    required List<AttendanceLog> logs,
    required List<AttendanceLog> filteredLogs,
    required String fileName,
  }) async {
    var excel = Excel.createExcel();
    
    String sheetName = "Attendance_Master_Report";
    excel.rename(excel.getDefaultSheet()!, sheetName);
    Sheet sheet = excel[sheetName];

    // --- COLOR PALETTE (Fixed CamelCase) ---
    final colorBlue = ExcelColor.fromHexString("#2979FF");
    final colorNavy = ExcelColor.fromHexString("#1A237E");
    final colorWhite = ExcelColor.fromHexString("#FFFFFF");
    final colorGrey = ExcelColor.fromHexString("#F5F5F5");

    // --- STYLES (Fixed Parameters) ---
    CellStyle titleStyle = CellStyle(
      bold: true,
      fontColorHex: colorNavy,
    );

    CellStyle summaryHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: colorGrey,
      fontColorHex: colorNavy,
    );

    CellStyle tableHeaderStyle = CellStyle(
      bold: true,
      fontColorHex: colorWhite,
      backgroundColorHex: colorBlue,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // --- 1. EXECUTIVE SUMMARY SECTION ---
    final int total = logs.length;
    final int approved = logs.where((l) => l.decision == AttendanceDecision.allowed).length;
    final int denied = total - approved;
    final double successRate = total > 0 ? (approved / total) * 100 : 0;

    sheet.appendRow([TextCellValue('MESS MANAGER EXECUTIVE REPORT')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    sheet.appendRow([TextCellValue('Audit Period: ${DateTime.now().toString().substring(0, 16)}')]);
    sheet.appendRow([TextCellValue('')]); 

    sheet.appendRow([
      TextCellValue('METRIC'), 
      TextCellValue('TOTAL COUNT'), 
      TextCellValue('PERCENTAGE DISTRIBUTION')
    ]);
    
    for (var i = 0; i < 3; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = summaryHeaderStyle;
    }

    sheet.appendRow([TextCellValue('Total Scans Attempted'), IntCellValue(total), TextCellValue('100%')]);
    sheet.appendRow([TextCellValue('Approved Entries'), IntCellValue(approved), TextCellValue('${successRate.toStringAsFixed(1)}%')]);
    sheet.appendRow([TextCellValue('Denied Entries'), IntCellValue(denied), TextCellValue('${(100 - successRate).toStringAsFixed(1)}%')]);
    
    sheet.appendRow([TextCellValue('')]); 
    sheet.appendRow([TextCellValue('MEAL WISE BREAKDOWN (GLOBAL)')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).cellStyle = summaryHeaderStyle;

    final bfast = logs.where((l) => l.mealType == MealType.breakfast).length;
    final lunch = logs.where((l) => l.mealType == MealType.lunch).length;
    final dinner = logs.where((l) => l.mealType == MealType.dinner).length;

    sheet.appendRow([TextCellValue('Breakfast Volume'), IntCellValue(bfast)]);
    sheet.appendRow([TextCellValue('Lunch Volume'), IntCellValue(lunch)]);
    sheet.appendRow([TextCellValue('Dinner Volume'), IntCellValue(dinner)]);

    sheet.appendRow([TextCellValue('')]); 
    sheet.appendRow([TextCellValue('')]); 

    // --- 2. DETAILED AUDIT LOG SECTION ---
    sheet.appendRow([TextCellValue('DETAILED ATTENDANCE LOG (FILTERED)')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13)).cellStyle = titleStyle;

    List<CellValue> headers = [
      TextCellValue('Student Name'),
      TextCellValue('PRN/ID'),
      TextCellValue('Meal'),
      TextCellValue('Status'),
      TextCellValue('Reason/Note'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Data Source'),
    ];
    
    sheet.appendRow(headers);
    const int headerRowIndex = 14; 

    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRowIndex)).cellStyle = tableHeaderStyle;
      sheet.setColumnWidth(i, 22.0);
    }

    for (var log in filteredLogs) {
      sheet.appendRow([
        TextCellValue(log.studentName),
        TextCellValue(log.studentId.split('_')[0]), 
        TextCellValue(log.mealLabel),
        TextCellValue(log.decision.name.toUpperCase()),
        TextCellValue(log.reason),
        TextCellValue("${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}"),
        TextCellValue("${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}"),
        TextCellValue(log.syncedToCloud ? 'Cloud Sync' : 'Device Local'),
      ]);
    }

    // --- 3. SAVE AND SHARE ---
    final List<int>? fileBytes = excel.save();
    
    if (fileBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.xlsx';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Master Attendance Report: $fileName',
      );
    }
  }
}