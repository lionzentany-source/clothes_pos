import 'dart:io';

import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

class DbBackupRestoreScreen extends StatefulWidget {
  const DbBackupRestoreScreen({super.key});

  @override
  State<DbBackupRestoreScreen> createState() => _DbBackupRestoreScreenState();
}

class _DbBackupRestoreScreenState extends State<DbBackupRestoreScreen> {
  bool _working = false;
  final _restorePathCtrl = TextEditingController();

  Future<String> _currentDbPath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'clothes_pos.db');
  }

  Future<void> _backup() async {
    final l = AppLocalizations.of(context); // capture before awaits
    setState(() => _working = true);
    try {
      final src = await _currentDbPath();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .split('.')
          .first;
      final suggested = 'clothes_pos_$ts.db';
      final typeGroup = const XTypeGroup(
        label: 'SQLite DB',
        extensions: ['db'],
      );
      final location = await getSaveLocation(
        acceptedTypeGroups: [typeGroup],
        suggestedName: suggested,
      );
      if (location == null) {
        return;
      }
      final destPath = location.path;
      await File(src).copy(destPath);
      if (!mounted) return;
      await _showInfo(l.done, l.backupCreatedAt(destPath));
    } catch (e) {
      await _showError(l.backupFailed, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restore() async {
    final l = AppLocalizations.of(context); // capture before awaits
    final path = _restorePathCtrl.text.trim();
    if (path.isEmpty) {
      await _showError(l.error, l.enterDbPathFirst);
      return;
    }
    setState(() => _working = true);
    try {
      if (!await File(path).exists()) throw Exception(l.fileDoesNotExist);
      // Compare schema versions
      final current = await openDatabase(await _currentDbPath());
      final curVerRow = await current.rawQuery('PRAGMA user_version');
      final curVer = (curVerRow.first.values.first as int?) ?? 0;
      await current.close();

      final backup = await openDatabase(path, readOnly: true);
      final bakVerRow = await backup.rawQuery('PRAGMA user_version');
      final bakVer = (bakVerRow.first.values.first as int?) ?? 0;
      await backup.close();

      if (curVer != bakVer) {
        // Ask user if they want to proceed despite mismatch
        final proceed = await _confirmVersionMismatch(curVer, bakVer);
        if (!proceed) {
          if (!mounted) return; // user cancelled
          await _showInfo(l.cancel, l.schemaVersionMismatch(curVer, bakVer));
          return;
        }
      }

      // Close and replace DB
      final helper = DatabaseHelper.instance;
      await helper.resetForTests(); // يغلق ويحذف الملف
      final dest = await _currentDbPath();
      await File(path).copy(dest);
      // Reopen
      await helper.database;
      if (!mounted) return;
      await _showInfo(l.done, l.restoreSuccess);
    } catch (e) {
      await _showError(l.restoreFailed, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool> _confirmVersionMismatch(int current, int backup) async {
    if (!mounted) return false;
    final l = AppLocalizations.of(context);
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(l.warning),
            content: Text(l.schemaVersionMismatch(current, backup)),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showInfo(String title, String msg) async {
    if (!mounted) return;
    final ctx = context;
    return showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showError(String title, String msg) async {
    if (!mounted) return;
    final ctx = context;
    return showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).closeAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.dbBackupRestore),
        trailing: _working ? const CupertinoActivityIndicator() : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.backupSection),
            const SizedBox(height: 8),
            CupertinoButton.filled(
              onPressed: _working ? null : _backup,
              child: Text(l.backupNow),
            ),
            const SizedBox(height: 24),
            Text(l.restoreSection),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _restorePathCtrl,
                    placeholder: l.dbFilePathPlaceholder,
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: _working
                      ? null
                      : () async {
                          final typeGroup = const XTypeGroup(
                            label: 'SQLite DB',
                            extensions: ['db'],
                          );
                          final file = await openFile(
                            acceptedTypeGroups: [typeGroup],
                          );
                          if (file != null) {
                            _restorePathCtrl.text = file.path;
                          }
                        },
                  child: Text(l.chooseFile),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: _working ? null : _restore,
              child: Text(l.restoreNow),
            ),
          ],
        ),
      ),
    );
  }
}
