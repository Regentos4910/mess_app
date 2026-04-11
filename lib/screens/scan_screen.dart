import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
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
  String _lastMessage = 'Point camera at student QR';

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
        title: const Text('Entry Scanner', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, child) {
              final torchState = state.torchState;
              return IconButton(
                icon: Icon(
                  torchState == TorchState.on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: torchState == TorchState.on ? Colors.yellowAccent : Colors.white,
                ),
                onPressed: () => _scannerController.toggleTorch(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
      children: <Widget>[
        MobileScanner(
          controller: _scannerController,
          onDetect: (BarcodeCapture capture) {
            if (_handlingScan) return;
            final String? rawValue = capture.barcodes.first.rawValue;
            if (rawValue != null && rawValue.trim().isNotEmpty) {
              // PRODUCTION ADDITION: Impact feedback
              HapticFeedback.mediumImpact(); 
              _handleScan(rawValue);
            }
          },
        ),
        _buildElegantOverlay(context),
        Positioned(
          left: 20,
          right: 20,
          bottom: 60, // Adjusted height since selector is gone
          child: Column(
            children: [
              _buildStatusChip(),
              // MEAL SELECTOR REMOVED FROM HERE
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildElegantOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(102),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 260,
                  width: 260,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(45)),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 260,
            width: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent.withAlpha(128), width: 2),
              borderRadius: BorderRadius.circular(45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 15)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            _lastMessage,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

Future<void> _handleScan(String qrPayload) async {
  if (_handlingScan) return;
  setState(() => _handlingScan = true);

  // Stop scanning while processing to prevent duplicate popups
  await _scannerController.stop(); 

  final outcome = widget.controller.inspectQrPayload(qrPayload);

  if (outcome == null) {
    _showErrorSnackBar('No record for this QR');
    await Future.delayed(const Duration(seconds: 1));
    await _scannerController.start(); // Restart camera
    setState(() => _handlingScan = false);
    return;
  }

  if (!mounted) return;

  final AttendanceDecision? decision = await showModalBottomSheet<AttendanceDecision>(
    context: context,
    isDismissible: true, // Production tip: Allow dismiss to resume scanning
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
    builder: (context) => _buildDecisionSheet(outcome),
  );

  if (decision != null) {
    final log = await widget.controller.recordAttendance(
      student: outcome.student,
      decision: decision,
      reason: decision == AttendanceDecision.allowed ? 'Authorized' : outcome.reason,
    );
    
    setState(() {
      _lastMessage = '${log.studentName}: ${decision.name.toUpperCase()}';
    });
  }

  // PRODUCTION REFINEMENT: Ensure camera restarts and wait for UI to settle
  await _scannerController.start(); 
  setState(() => _handlingScan = false);
}

  Widget _buildDecisionSheet(ScanOutcome outcome) {
    final student = outcome.student;
    final isAllowed = outcome.recommendedDecision == AttendanceDecision.allowed;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. DYNAMIC ASPECT RATIO PHOTO
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: size.height * 0.5, // Limit to 50% of screen height
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                color: Colors.grey.shade50, // Soft background if image is narrow
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: student.photoPath.isNotEmpty && File(student.photoPath).existsSync()
                    ? Image.file(
                        File(student.photoPath),
                        fit: BoxFit.contain, // Respects original aspect ratio
                      )
                    : const Center(
                        child: Icon(Icons.person_rounded, size: 120, color: Colors.blueAccent),
                      ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(
              children: [
                Text(student.name, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
                const SizedBox(height: 4),
                Text('PRN: ${student.prn}', 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 24),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isAllowed ? Colors.greenAccent.withAlpha(25) : Colors.redAccent.withAlpha(12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isAllowed ? Colors.greenAccent.withAlpha(76) : Colors.redAccent.withAlpha(51)),
                  ),
                  child: Text(
                    outcome.reason,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isAllowed ? Colors.green.shade800 : Colors.redAccent, 
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, AttendanceDecision.denied),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('DENY ENTRY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAllowed ? () => Navigator.pop(context, AttendanceDecision.allowed) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('ALLOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 120, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}