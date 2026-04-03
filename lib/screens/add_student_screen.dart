import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/student.dart';
import '../services/app_controller.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({
    required this.controller,
    super.key,
  });

  static const String routeName = '/students/add';
  final AppController controller;

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prnController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _membershipActive = true;
  String _photoPath = '';
  Student? _createdStudent;

  @override
  void dispose() {
    _nameController.dispose();
    _prnController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title: const Text('Enroll Student', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: <Widget>[
                const SizedBox(height: 20),
                
                // 1. Vibrant Circular Photo Section
                Center(child: _buildPhotoPicker()),
                
                const SizedBox(height: 40),

                // 2. Minimal Rounded Form Fields
                _buildTextField(
                  controller: _nameController,
                  label: 'Student Full Name',
                  icon: Icons.person_outline_rounded,
                  hint: 'Enter full name',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _prnController,
                  label: 'PRN Number',
                  icon: Icons.badge_outlined,
                  hint: 'Unique ID code',
                  isNumber: true,
                ),

                const SizedBox(height: 20),
                _buildTextField( // Added this block
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_android_rounded,
                  hint: 'Enter mobile number',
                  isNumber: true,
                ),
                
                const SizedBox(height: 12),

                // 3. Compact Switch Pill
                _buildMembershipToggle(),

                const SizedBox(height: 32),

                // 4. Vibrant Save Button
                _buildSaveButton(),

                // 5. Success State (QR Result)
                if (_createdStudent != null) _buildSuccessResult(),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent.withAlpha(51), width: 2),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade50,
              backgroundImage: _photoPath.isNotEmpty ? FileImage(File(_photoPath)) : null,
              child: _photoPath.isEmpty
                  ? const Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.blueAccent)
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black54)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipToggle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _membershipActive ? Colors.tealAccent.withAlpha(13) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _membershipActive ? Colors.tealAccent.withAlpha(77) : Colors.grey.shade200),
      ),
      child: SwitchListTile.adaptive(
        value: _membershipActive,
        onChanged: (v) => setState(() => _membershipActive = v),
        title: const Text('Authorize Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        activeThumbColor: Colors.tealAccent.shade700,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool isBusy = widget.controller.busy;
    return ElevatedButton(
      onPressed: isBusy ? null : _saveStudent,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 0,
      ),
      child: Text(
        isBusy ? 'REGISTERING...' : 'REGISTER STUDENT',
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSuccessResult() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 40),
        const SizedBox(height: 12),
        const Text('Enrollment Complete', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              Text('STUDENT ACCESS KEY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              QrImageView(
                data: _createdStudent!.qrPayload,
                size: 180,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black87),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              SelectableText(_createdStudent!.id, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _capturePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 800,
      imageQuality: 65,
    );
    if (image == null) return;
    setState(() => _photoPath = image.path);
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student photo required'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      final Student student = await widget.controller.addStudent(
        StudentDraft(
          name: _nameController.text,
          prn: _prnController.text,
          phoneNumber: _phoneController.text,
          membershipActive: _membershipActive,
          photoPath: _photoPath,
        ),
      );

      setState(() {
        _createdStudent = student;
        _nameController.clear();
        _prnController.clear();
        _phoneController.clear();
        _membershipActive = true;
        _photoPath = '';
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}