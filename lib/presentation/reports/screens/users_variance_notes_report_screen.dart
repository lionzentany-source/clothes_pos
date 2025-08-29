import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';

class UsersVarianceNotesReportScreen extends StatefulWidget {
  const UsersVarianceNotesReportScreen({super.key});

  @override
  State<UsersVarianceNotesReportScreen> createState() =>
      _UsersVarianceNotesReportScreenState();
}

class _UsersVarianceNotesReportScreenState
    extends State<UsersVarianceNotesReportScreen> {
  List<Map<String, Object?>> _managerNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadManagerNotes();
  }

  Future<void> _loadManagerNotes() async {
    setState(() => _loading = true);
    try {
      final dbHelper = sl<DatabaseHelper>();
      final db = await dbHelper.database;
      final notes = await db.query(
        'audit_log',
        where: 'action = ?',
        whereArgs: ['variance_note'],
        orderBy: 'created_at DESC',
        limit: 30,
      );
      if (mounted) {
        setState(() {
          _managerNotes = notes;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.w('Failed to load manager notes', error: e);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ملاحظات فرق الكاش للمستخدمين'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _managerNotes.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد ملاحظات فرق كاش مسجلة',
                  style: TextStyle(fontSize: AppTypography.fs16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _managerNotes.length,
                itemBuilder: (context, index) {
                  final note = _managerNotes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (note['new_value'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: AppTypography.fs14,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المستخدم: ${note['user_id'] ?? 'غير معروف'}',
                          style: const TextStyle(
                            fontSize: AppTypography.fs12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        if (note['created_at'] != null)
                          Text(
                            'تاريخ: ${note['created_at'].toString().substring(0, 19).replaceAll('T', ' ')}',
                            style: const TextStyle(
                              fontSize: AppTypography.fs12,
                              color: CupertinoColors.systemGrey2,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
