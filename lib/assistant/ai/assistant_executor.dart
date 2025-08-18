import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/presentation/pos/screens/pos_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_home_screen.dart';
import 'package:clothes_pos/presentation/reports/screens/reports_home_screen.dart';
import 'package:clothes_pos/presentation/settings/screens/settings_home_screen.dart';
import 'ai_models.dart';

class AssistantExecutor {
  final ReportsRepository reportsRepo = sl<ReportsRepository>();
  final DatabaseHelper dbHelper = sl<DatabaseHelper>();

  Future<String?> execute(BuildContext context, AiAction action) async {
    if (action is OpenScreenAction) {
      _open(context, action);
      return 'حاضر، قمت بفتح الشاشة المطلوبة.';
    }
    if (action is AnswerFaqAction) {
      return action.text;
    }
    if (action is QueryMetricAction) {
      final msg = await _handleMetric(action);
      return msg;
    }
    return 'خارج نطاق المنظومة';
  }

  void _open(BuildContext context, OpenScreenAction a) {
    final nav = Navigator.of(context);
    Widget screen;
    switch (a.tab) {
      case 'pos':
        screen = const PosScreen();
        break;
      case 'inventory':
        screen = const InventoryHomeScreen();
        break;
      case 'reports':
        screen = const ReportsHomeScreen();
        break;
      case 'settings':
      default:
        screen = const SettingsHomeScreen();
    }
    nav.push(CupertinoPageRoute(builder: (_) => screen));
  }

  Future<String> _handleMetric(QueryMetricAction a) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (a.range) {
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        start = DateTime(y.year, y.month, y.day);
        end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;
      case 'week':
        final monday = now.subtract(Duration(days: (now.weekday - 1)));
        start = DateTime(monday.year, monday.month, monday.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'today':
      default:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    final sIso = start.toIso8601String();
    final eIso = end.toIso8601String();

    if (a.metric == 'returns') {
      final total = await _sumRefunds(sIso, eIso);
      return 'بكل سرور، قيمة المرتجعات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == 'sales') {
      final total = await _sumSales(sIso, eIso);
      return 'تمام، إجمالي المبيعات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == 'expenses') {
      final total = await reportsRepo.expensesTotalByDate(startIso: sIso, endIso: eIso);
      return 'بكل عناية، إجمالي المصروفات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == 'profit') {
      final sales = await _sumSales(sIso, eIso);
      final purchases = await reportsRepo.purchasesTotalByDate(startIso: sIso, endIso: eIso);
      final expenses = await reportsRepo.expensesTotalByDate(startIso: sIso, endIso: eIso);
      final profit = sales - purchases - expenses;
      return 'على الرحب والسعة، صافي الأرباح ${profit.toStringAsFixed(2)}.';
    }
    return 'خارج نطاق المنظومة';
  }

  Future<double> _sumRefunds(String startIso, String endIso) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      """
      SELECT SUM(amount) AS total
      FROM payments
      WHERE method = 'REFUND'
        AND datetime(created_at) >= datetime(?)
        AND datetime(created_at) <= datetime(?)
      """,
      [startIso, endIso],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> _sumSales(String startIso, String endIso) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      """
      SELECT SUM(si.quantity * si.price_per_unit) AS total
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      WHERE datetime(s.sale_date) >= datetime(?) AND datetime(s.sale_date) <= datetime(?)
      """,
      [startIso, endIso],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

