import 'dart:io';

void main() {
  final repoRoot = Directory.current;
  final dotTool = Directory(
    '${repoRoot.path}${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}sqflite_common_ffi${Platform.pathSeparator}databases',
  );
  if (!dotTool.existsSync()) {
    print(
      'No .dart_tool/sqflite_common_ffi/databases folder found — nothing to clean.',
    );
    return;
  }

  final duplicates = <File>[];
  for (final f in dotTool.listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.db')) {
      final p = f.path.replaceAll('\\', '/');
      // identify nested repeated .dart_tool segments or deeply nested clones
      if (p.contains('/.dart_tool/sqflite_common_ffi/databases/.dart_tool')) {
        duplicates.add(f);
      }
    }
  }

  if (duplicates.isEmpty) {
    print('No duplicate DB files found under .dart_tool.');
    return;
  }

  print('Found ${duplicates.length} duplicate DB file(s) to remove:');
  for (final d in duplicates) {
    print('- ${d.path}');
  }

  for (final d in duplicates) {
    try {
      d.deleteSync();
      print('Deleted: ${d.path}');
    } catch (e) {
      print('Failed to delete ${d.path}: $e');
    }
  }
}
