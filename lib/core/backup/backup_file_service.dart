import 'dart:io';

class BackupFileService {
  final String backupDirPath;

  BackupFileService(this.backupDirPath);

  Future<Directory> _ensureDir() async {
    final dir = Directory(backupDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> saveBackup(String fileName, String json) async {
    final dir = await _ensureDir();
    final finalPath = '${dir.path}/$fileName';
    final tempPath = '$finalPath.tmp';

    final tempFile = File(tempPath);
    await tempFile.writeAsString(json, flush: true);

    final finalFile = File(finalPath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await tempFile.rename(finalPath);
  }

  Future<String?> loadBackup(String fileName) async {
    final dir = await _ensureDir();
    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  Future<List<String>> listBackups() async {
    final dir = await _ensureDir();
    final entities = await dir.list().toList();
    final names = <String>[];
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        names.add(entity.uri.pathSegments.last);
      }
    }
    names.sort((a, b) => b.compareTo(a));
    return names;
  }

  Future<void> deleteBackup(String fileName) async {
    final dir = await _ensureDir();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
