import 'dart:convert';
import 'dart:io';

class LocalStorageService {
  const LocalStorageService();

  Future<Map<String, dynamic>> readState() async {
    final File file = await _stateFile();
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

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
    final Directory root = await _appDirectory();
    final Directory photosDir = Directory('${root.path}/photos');
    await photosDir.create(recursive: true);
    final String extension = sourcePath.contains('.')
        ? sourcePath.split('.').last
        : 'jpg';
    final File target = File('${photosDir.path}/$studentId.$extension');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  Future<File> _stateFile() async {
    final Directory root = await _appDirectory();
    return File('${root.path}/mess_app_state.json');
  }

  Future<Directory> _appDirectory() async {
    return Directory('${Directory.systemTemp.path}/mess_app_local');
  }
}
