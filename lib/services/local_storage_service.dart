import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Add this package

class LocalStorageService {
  const LocalStorageService();

  // CHANGE 1: Make appDirectory public so AppController can see it
  // CHANGE 2: Use getApplicationDocumentsDirectory() instead of systemTemp
  Future<Directory> appDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/mess_app_data_v1');
  }

  Future<Map<String, dynamic>> readState() async {
    final File file = await _stateFile();
    if (!await file.exists()) return <String, dynamic>{};
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeState(Map<String, dynamic> state) async {
    final File file = await _stateFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state));
  }

  Future<String> persistStudentPhoto({
    required String studentId,
    required String sourcePath,
  }) async {
    final Directory root = await appDirectory(); // Use updated public method
    final Directory photosDir = Directory('${root.path}/photos');
    await photosDir.create(recursive: true);
    
    final String extension = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final File target = File('${photosDir.path}/$studentId.$extension');
    
    // Safety check: delete if exists to avoid "File busy" errors
    if (await target.exists()) await target.delete();
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  Future<File> _stateFile() async {
    final Directory root = await appDirectory(); // Use updated public method
    return File('${root.path}/mess_app_state.json');
  }
}