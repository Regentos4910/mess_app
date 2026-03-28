import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/attendance.dart';
import '../services/app_controller.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/scan';
  final AppController controller;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handlingScan = false;
  String _lastMessage = 'Ready to scan';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Attendance'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) {
              if (_handlingScan) {
                return;
              }
              final String? rawValue = capture.barcodes.first.rawValue;
              if (rawValue == null || rawValue.trim().isEmpty) {
                return;
              }
              _handleScan(rawValue);
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              color: Colors.black.withValues(alpha: 0.74),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Scanner stays open after every decision.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastMessage,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        ...MealType.values.map(
                          (MealType meal) => ChoiceChip(
                            label: Text(_mealLabel(meal)),
                            selected: widget.controller.selectedMeal == meal,
                            onSelected: (_) => widget.controller.setSelectedMeal(meal),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String qrPayload) async {
    setState(() {
      _handlingScan = true;
    });
    await _scannerController.stop();

    final ScanOutcome? outcome = widget.controller.inspectQrPayload(qrPayload);
    if (!mounted) {
      return;
    }

    if (outcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student not found for this QR code.')),
      );
      setState(() {
        _lastMessage = 'Student not found';
        _handlingScan = false;
      });
      await _scannerController.start();
      return;
    }

    final AttendanceDecision? decision = await showModalBottomSheet<AttendanceDecision>(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        final bool recommendedAllow =
            outcome.recommendedDecision == AttendanceDecision.allowed;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  outcome.student.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text('PRN: ${outcome.student.prn}'),
                Text(outcome.student.subtitle),
                const SizedBox(height: 12),
                Text(outcome.reason),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pop(AttendanceDecision.denied),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Deny Entry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: recommendedAllow
                            ? () => Navigator.of(context)
                                .pop(AttendanceDecision.allowed)
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Allow Entry'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (decision != null) {
      final String reason = decision == AttendanceDecision.allowed
          ? 'Entry allowed by staff'
          : outcome.reason;
      final AttendanceLog log = await widget.controller.recordAttendance(
        student: outcome.student,
        decision: decision,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${log.studentName}: ${decision == AttendanceDecision.allowed ? 'Allowed' : 'Denied'}',
          ),
        ),
      );
      setState(() {
        _lastMessage =
            '${log.studentName} ${decision == AttendanceDecision.allowed ? 'allowed' : 'denied'} for ${log.mealLabel}';
      });
    }

    setState(() {
      _handlingScan = false;
    });
    await _scannerController.start();
  }

  String _mealLabel(MealType meal) {
    return switch (meal) {
      MealType.breakfast => 'Breakfast',
      MealType.lunch => 'Lunch',
      MealType.dinner => 'Dinner',
    };
  }
}
