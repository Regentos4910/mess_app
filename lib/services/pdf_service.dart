import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance.dart';

class PdfService {
  static Future<void> generateAndShare({
    required List<AttendanceLog> logs,
    required List<AttendanceLog> filteredLogs,
    required String fileName,
    required DateTime start,
    required DateTime end,
    required String mealFilter,
  }) async {
    final pdf = pw.Document(
      author: 'Mess Manager Enterprise',
      title: 'Operational Audit & Analytics Report',
    );

    // Modern Enterprise Palette
    const PdfColor primaryBlue = PdfColor.fromInt(0xFF2979FF);
    const PdfColor secondaryNavy = PdfColor.fromInt(0xFF1A237E);
    const PdfColor surfaceGrey = PdfColor.fromInt(0xFFF8F9FA);
    const PdfColor successGreen = PdfColor.fromInt(0xFF2E7D32);
    const PdfColor errorRed = PdfColor.fromInt(0xFFC62828);

    // Analytics Calculation
    final int total = logs.length;
    final int approved = logs.where((l) => l.decision == AttendanceDecision.allowed).length;
    final int denied = total - approved;
    
    final double bfast = logs.where((l) => l.mealType == MealType.breakfast).length.toDouble();
    final double lunch = logs.where((l) => l.mealType == MealType.lunch).length.toDouble();
    final double dinner = logs.where((l) => l.mealType == MealType.dinner).length.toDouble();

    // Daily Trend Calculation (Groups logs by day)
    final Map<String, int> dailyCounts = {};
    for (var log in logs) {
      final String d = "${log.timestamp.day}/${log.timestamp.month}";
      dailyCounts[d] = (dailyCounts[d] ?? 0) + 1;
    }
    final trendData = dailyCounts.entries.toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('MESS MANAGER BI REPORT - CONFIDENTIAL',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          // 1. BRANDED HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MESS MANAGER',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: secondaryNavy)),
                  pw.Text('OPERATIONAL AUDIT & ANALYTICS',
                      style: pw.TextStyle(fontSize: 9, color: primaryBlue, letterSpacing: 1.5)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('REPORT ID: #AUD-${DateTime.now().millisecondsSinceEpoch}',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text('EXPORT DATE: ${DateTime.now().toString().substring(0, 19)}',
                      style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          // 2. AUDIT TRAIL DATA
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: surfaceGrey, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem('RANGE START', start.toString().substring(0, 10)),
                _buildMetaItem('RANGE END', end.toString().substring(0, 10)),
                _buildMetaItem('MEAL TYPE', mealFilter),
                _buildMetaItem('EXPORT SIZE', '${filteredLogs.length} Records'),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          // 3. KPI TILES
          pw.Row(
            children: [
              _buildStatCard('TOTAL ATTEMPTS', total.toString(), primaryBlue, surfaceGrey, '100%'),
              pw.SizedBox(width: 10),
              _buildStatCard('APPROVED', approved.toString(), successGreen, surfaceGrey, '${total > 0 ? (approved / total * 100).toStringAsFixed(1) : 0}%'),
              pw.SizedBox(width: 10),
              _buildStatCard('DENIED', denied.toString(), errorRed, surfaceGrey, '${total > 0 ? (denied / total * 100).toStringAsFixed(1) : 0}%'),
            ],
          ),
          pw.SizedBox(height: 30),

          // 4. BI VISUALIZATIONS (Graphs)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bar Chart: Volume Distribution
              pw.Expanded(
                flex: 2,
                child: pw.Column(children: [
                  pw.Text('MEAL VOLUME DISTRIBUTION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    height: 100,
                    child: pw.Chart(
                      grid: pw.CartesianGrid(
                        xAxis: pw.FixedAxis.fromStrings(['B-Fast', 'Lunch', 'Dinner'], textStyle: const pw.TextStyle(fontSize: 6)),
                        yAxis: pw.FixedAxis([0, total.toDouble()], textStyle: const pw.TextStyle(fontSize: 6)),
                      ),
                      datasets: [
                        pw.BarDataSet(
                          color: primaryBlue,
                          width: 18,
                          data: [
                            pw.PointChartValue(0, bfast),
                            pw.PointChartValue(1, lunch),
                            pw.PointChartValue(2, dinner),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              pw.SizedBox(width: 30),
            ],
          ),
          pw.SizedBox(height: 30),

          // 5. TREND VISUALIZATION (Line Chart)
          pw.Text('ATTENDANCE TREND (DAILY VOLUME)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 80,
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis([0, trendData.length.toDouble()], textStyle: const pw.TextStyle(fontSize: 6)),
                yAxis: pw.FixedAxis([0, total.toDouble()], textStyle: const pw.TextStyle(fontSize: 6)),
              ),
              datasets: [
                pw.LineDataSet(
                  color: primaryBlue,
                  drawPoints: true,
                  pointSize: 2,
                  data: List.generate(trendData.length, (i) => pw.PointChartValue(i.toDouble(), trendData[i].value.toDouble())),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // 6. DATA TABLE
          pw.Text('DETAILED AUDIT LOG (FILTERED)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: secondaryNavy),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            headers: ['STUDENT NAME', 'PRN', 'MEAL', 'DECISION', 'TIME'],
            data: filteredLogs.map((log) => [
              log.studentName,
              log.studentId.split('_')[0],
              log.mealLabel,
              log.decision == AttendanceDecision.allowed ? 'APPROVED' : 'DENIED',
              log.timestamp.toString().substring(5, 16),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '$fileName.pdf');
  }

  static pw.Widget _buildMetaItem(String label, String val) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
      pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
    ],
  );

  static pw.Widget _buildStatCard(String label, String val, PdfColor color, PdfColor bgColor, String sub) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: color, width: 2.5)),
        color: bgColor,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(val, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(sub, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    ),
  );
}