import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileManager {
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  // Get local app directory
  Future<Directory> get _localDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final filesDir = Directory(path.join(directory.path, 'imported_files'));
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  // Pick text files from storage
  Future<List<File>?> pickTextFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return null;
    } catch (e) {
      print('Error picking files: $e');
      return null;
    }
  }

  // Generate a unique filename in the target directory
  Future<String> _getUniqueFilename(Directory localDir, String originalFileName) async {
    String baseName = path.basenameWithoutExtension(originalFileName);
    String extension = path.extension(originalFileName);
    String targetPath = path.join(localDir.path, originalFileName);
    int counter = 1;

    // Keep trying new filenames until we find one that doesn't exist
    while (await File(targetPath).exists()) {
      String newFileName = '$baseName($counter)$extension';
      targetPath = path.join(localDir.path, newFileName);
      counter++;
    }

    return targetPath;
  }

  // Copy file to local storage
  Future<String?> copyFileToLocal(File sourceFile) async {
    try {
      final localDir = await _localDirectory;
      final fileName = path.basename(sourceFile.path);
      
      // Get a unique filename for the destination
      final uniquePath = await _getUniqueFilename(localDir, fileName);
      final localFile = File(uniquePath);

      // Copy the file with the unique name
      await sourceFile.copy(localFile.path);
      return localFile.path;
    } catch (e) {
      print('Error copying file: $e');
      return null;
    }
  }

  // Get all imported files
  Future<List<File>> getImportedFiles() async {
    try {
      final localDir = await _localDirectory;
      final files = await localDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .toList();
    } catch (e) {
      print('Error getting imported files: $e');
      return [];
    }
  }

  // Delete imported file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Read file content
  Future<String?> readFileContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }

  // Write file content
  Future<bool> writeFileContent(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }
}
