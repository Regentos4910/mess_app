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
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _membershipActive = true;
  String _photoPath = '';
  Student? _createdStudent;

  @override
  void dispose() {
    _nameController.dispose();
    _prnController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Add Student')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFFCCFBF1),
                      backgroundImage:
                          _photoPath.isNotEmpty ? FileImage(File(_photoPath)) : null,
                      child: _photoPath.isEmpty
                          ? const Icon(Icons.camera_alt, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Capture student photo'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Student name'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prnController,
                  decoration: const InputDecoration(labelText: 'PRN'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(labelText: 'Course name'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Year of study'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _divisionController,
                  decoration: const InputDecoration(labelText: 'Division'),
                  validator: _requiredField,
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _membershipActive,
                  onChanged: (bool value) {
                    setState(() {
                      _membershipActive = value;
                    });
                  },
                  title: const Text('Membership active'),
                  subtitle: const Text(
                    'Inactive students can be scanned, but their entry will be denied.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.controller.busy ? null : _saveStudent,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    widget.controller.busy ? 'Saving...' : 'Save student',
                  ),
                ),
                if (_createdStudent != null) ...<Widget>[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Student QR',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _createdStudent!.qrPayload,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _createdStudent!.qrPayload,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (image == null) {
      return;
    }
    setState(() {
      _photoPath = image.path;
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Student student = await widget.controller.addStudent(
      StudentDraft(
        name: _nameController.text,
        prn: _prnController.text,
        studyYear: _yearController.text,
        courseName: _courseController.text,
        division: _divisionController.text,
        membershipActive: _membershipActive,
        photoPath: _photoPath,
      ),
    );

    setState(() {
      _createdStudent = student;
      _nameController.clear();
      _prnController.clear();
      _yearController.clear();
      _courseController.clear();
      _divisionController.clear();
      _membershipActive = true;
      _photoPath = '';
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${student.name} added successfully.')),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
