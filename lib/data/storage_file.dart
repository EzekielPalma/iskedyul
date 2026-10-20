import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_contract.dart';

// Android stores this snapshot in the app's private directory. No storage
// permission is needed. The same JSON format is used by the browser version.
class FileStorage implements SnapshotStorage {
  FileStorage(this.file);
  final File file;

  @override
  String? read() => file.existsSync() ? file.readAsStringSync() : null;

  @override
  void write(String value) {
    // Finish writing before replacing the previous snapshot, so an interrupted
    // write leaves the last saved planner available.
    final pending = File('${file.path}.tmp');
    pending.writeAsStringSync(value, flush: true);
    pending.renameSync(file.path);
  }
}

Future<SnapshotStorage> createStorage() async {
  try {
    final directory = await getApplicationSupportDirectory();
    directory.createSync(recursive: true);
    return FileStorage(File('${directory.path}/iskedyul.data.v1.json'));
  } catch (_) {
    // Let AppState show its storage warning and keep the planner usable in
    // memory rather than failing to launch or claiming that changes were saved.
    return _UnavailableStorage();
  }
}

class _UnavailableStorage implements SnapshotStorage {
  @override
  String? read() => throw const FileSystemException('Storage unavailable');

  @override
  void write(String value) =>
      throw const FileSystemException('Storage unavailable');
}
