import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database_helper.dart';

/// Handles exporting the local database to a JSON file (shareable to another
/// device) and importing one back in.
class BackupService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Writes all data to a timestamped JSON file in a temp directory and opens
  /// the system share sheet so it can be sent to another device or saved to a
  /// cloud drive. Returns the file path written.
  Future<String> exportToShare() async {
    final data = _db.exportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/productivity_planner_backup_$stamp.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Productivity Planner backup',
    );
    return file.path;
  }

  /// Lets the user pick a previously-exported JSON file and replaces all local
  /// data with its contents. Returns true if an import happened, false if the
  /// user cancelled.
  Future<bool> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final picked = result.files.single;
    String contents;
    if (picked.bytes != null) {
      contents = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      contents = await File(picked.path!).readAsString();
    } else {
      return false;
    }

    final data = jsonDecode(contents) as Map<String, dynamic>;
    await _db.importData(data);
    return true;
  }
}