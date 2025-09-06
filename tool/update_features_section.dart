import 'dart:io';

// Simple script to sync FEATURES_AR.md into README.md between markers.
// Usage: dart run tool/update_features_section.dart

const startMarker = '<!-- FEATURES_AR_START -->';
const endMarker = '<!-- FEATURES_AR_END -->';

void main() {
  final repoRoot = Directory.current.path;
  final readmeFile = File('README.md');
  final featuresFile = File('FEATURES_AR.md');

  if (!readmeFile.existsSync()) {
    stderr.writeln('README.md not found in current directory: ' + repoRoot);
    exitCode = 1;
    return;
  }
  if (!featuresFile.existsSync()) {
    stderr.writeln('FEATURES_AR.md not found; create it first.');
    exitCode = 2;
    return;
  }

  final readme = readmeFile.readAsStringSync();
  final featuresRaw = featuresFile.readAsStringSync().trim();

  final featuresSection = StringBuffer()
    ..writeln(startMarker)
    ..writeln(featuresRaw)
    ..writeln()
    ..writeln(endMarker);

  if (readme.contains(startMarker) && readme.contains(endMarker)) {
    final updated = readme.replaceFirst(
      RegExp(startMarker + r'[\s\S]*?' + endMarker),
      featuresSection.toString(),
    );
    readmeFile.writeAsStringSync(updated);
    stdout.writeln('Updated features section inside README.md');
  } else {
    // Append at end with separator.
    readmeFile.writeAsStringSync(
      readme.trimRight() + '\n\n---\n' + featuresSection.toString() + '\n',
    );
    stdout.writeln('Appended features section to README.md (markers were missing).');
  }
}