import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
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
      return await _handleMetric(action);
    }
    if (action is SearchProductAction) {
      return await _handleProductSearch(action);
    }
    // --- NEW Action Handlers ---
    if (action is ForecastDemandAction) {
      return await _handleForecastDemand(action);
    }
    if (action is AnalyzeRootCauseAction) {
      return await _handleAnalyzeRootCause(action);
    }
    if (action is GenerateProductDescriptionAction) {
      return await _handleGenerateProductDescription(action);
    }
    if (action is SearchCustomerAction) {
      return await _handleCustomerSearch(action);
    }
    if (action is QueryInventoryAction) {
      return await _handleQueryInventory(action);
    }
    if (action is AddProductAction) {
      return await _handleAddProduct(action);
    }
    if (action is CreateReportAction) {
      return await _handleCreateReport(action);
    }
    return 'عفواً، لم أفهم هذا الطلب بعد.';
  }

  // --- NEW Action Handlers (with implementation) ---

  Future<String> _handleForecastDemand(ForecastDemandAction action) async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    DateTime startDate;
    int divisor;
    String periodName;
    String forecastPeriod;

    switch (action.period) {
      case 'next_month':
        startDate = DateTime(now.year, now.month - 3, now.day);
        divisor = 3;
        periodName = 'شهرياً';
        forecastPeriod = 'الشهر القادم';
        break;
      case 'next_week':
      default:
        startDate = now.subtract(const Duration(days: 28));
        divisor = 4;
        periodName = 'أسبوعياً';
        forecastPeriod = 'الأسبوع القادم';
        break;
    }

    final rows = await db.rawQuery(
      '''
      SELECT SUM(si.quantity) as total
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN product_variants pv ON si.product_variant_id = pv.id
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      WHERE pp.name LIKE ? AND s.sale_date BETWEEN ? AND ?
      ''',
      [
        '%${action.productName}%',
        startDate.toIso8601String(),
        now.toIso8601String(),
      ],
    );

    final totalSold = (rows.first['total'] as num?)?.toDouble() ?? 0.0;

    if (totalSold == 0) {
      return 'عفواً، لا توجد بيانات مبيعات كافية للمنتج "${action.productName}" لتوقع الطلب.';
    }

    final forecast = (totalSold / divisor).ceil();

    return 'بناءً على بيانات المبيعات، من المتوقع أن يكون الطلب على المنتج "${action.productName}" حوالي $forecast قطعة خلال $forecastPeriod (بمتوسط $periodName).';
  }

  Future<String> _handleAnalyzeRootCause(AnalyzeRootCauseAction action) async {
    // TODO: Implement actual root cause analysis logic.
    // This would involve querying various data points around the event date.
    return 'جاري تحليل السبب الجذري للحدث: ${action.eventDescription} بتاريخ ${action.date}.';
  }

  Future<String> _handleGenerateProductDescription(
    GenerateProductDescriptionAction action,
  ) async {
    // TODO: Implement actual description generation logic.
    // This could call a separate, more creative AI model or use templates.
    return 'سأقوم بإنشاء وصف تسويقي للمنتج: ${action.productName} باستخدام الكلمات المفتاحية: ${action.keywords.join(', ')}.';
  }

  Future<String> _handleCustomerSearch(SearchCustomerAction action) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT name, phone_number FROM customers WHERE name LIKE ? OR phone_number LIKE ? LIMIT 10',
      ['%${action.query}%', '%${action.query}%'],
    );

    if (rows.isEmpty) {
      return 'عفواً، لم أجد أي عميل بهذا الاسم أو الرقم: ${action.query}';
    }

    final count = rows.length;
    final customers = rows
        .map(
          (row) =>
              '- ${row['name']} (الرقم: ${row['phone_number'] ?? 'لا يوجد'})',
        )
        .join('\n');
    return 'بالتأكيد، وجدت $count عميل(لاء):\n$customers';
  }

  Future<String> _handleQueryInventory(QueryInventoryAction action) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      '''
  SELECT p.name, v.id, v.size, v.color, v.quantity
      FROM parent_products p JOIN product_variants v ON v.parent_product_id = p.id
      WHERE p.name LIKE ? OR v.size LIKE ? OR v.color LIKE ?
      ORDER BY v.quantity ASC
      LIMIT 10
    ''',
      ['%${action.query}%', '%${action.query}%', '%${action.query}%'],
    );

    if (rows.isEmpty) {
      return 'لا توجد منتجات تطابق بحثك: ${action.query}';
    }

    final count = rows.length;

    // Enrich with attribute values when feature flag is enabled
    if (FeatureFlags.useDynamicAttributes && rows.isNotEmpty) {
      try {
        final attrDao = AttributeDao(DatabaseHelper.instance);
        for (final r in rows) {
          final vid = (r['id'] as int?);
          if (vid != null) {
            final vals = await attrDao.getAttributeValuesForVariant(vid);
            r['attributes'] = vals.map((v) => v.toMap()).toList();
          } else {
            r['attributes'] = [];
          }
        }
      } catch (_) {
        // ignore enrichment errors
      }
    }

    final products = rows
        .map((row) {
          final name = row['name'];
          final attrs =
              (row['attributes'] as List?)
                  ?.map(
                    (a) => a is Map
                        ? (a['value'] ?? a['name'] ?? a.toString())
                        : a.toString(),
                  )
                  .where((x) => x != null)
                  .join(' • ') ??
              '';
          final qty = row['quantity'];
          final attrsPart = attrs.isNotEmpty ? ' — $attrs' : '';
          final size = row['size'] != null ? ' مقاس ${row['size']}' : '';
          return '- $name$size$attrsPart (الكمية: $qty)';
        })
        .join('\n');

    return 'وجدت $count منتج(ات) مطابقة:\n$products';
  }

  Future<String> _handleAddProduct(AddProductAction action) async {
    final db = await dbHelper.database;
    try {
      final parentProductId = await db.insert('parent_products', {
        'name': action.name,
        'category': action.category,
      });
      await db.insert('product_variants', {
        'parent_product_id': parentProductId,
        'sale_price': action.salePrice,
        'quantity': action.quantity,
        'size': action.size,
        'color': action.color,
      });
      return 'تمت إضافة المنتج ${action.name} بنجاح.';
    } catch (e) {
      return 'حدث خطأ أثناء إضافة المنتج: ${e.toString()}';
    }
  }

  Future<String> _handleCreateReport(CreateReportAction action) async {
    // In a real implementation, this would generate and possibly display a report.
    return 'بالتأكيد، سأقوم بإنشاء تقرير ${action.type} عن فترة ${action.range}.';
  }

  // --- Existing Handlers (Modified) ---

  Future<String> _handleProductSearch(SearchProductAction action) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        pp.name,
        pv.id,
        pv.size,
        pv.color,
        pv.sale_price,
        pv.quantity
      FROM parent_products pp
      JOIN product_variants pv ON pv.parent_product_id = pp.id
      WHERE pp.name LIKE ?
      LIMIT 10
      ''',
      ['%${action.query}%'],
    );

    if (rows.isEmpty) {
      return 'عفواً، لم أجد أي منتج بهذا الاسم.';
    }
    final count = rows.length;

    if (FeatureFlags.useDynamicAttributes && rows.isNotEmpty) {
      try {
        final attrDao = AttributeDao(DatabaseHelper.instance);
        for (final r in rows) {
          final vid = (r['id'] as int?);
          if (vid != null) {
            final vals = await attrDao.getAttributeValuesForVariant(vid);
            r['attributes'] = vals.map((v) => v.toMap()).toList();
          } else {
            r['attributes'] = [];
          }
        }
      } catch (_) {
        // ignore enrichment errors
      }
    }

    final products = rows
        .map((row) {
          final name = row['name'];
          final size = row['size'] != null ? ' مقاس ${row['size']}' : '';
          final color = row['color'] != null ? ' لون ${row['color']}' : '';
          final price = row['sale_price'];
          final qty = row['quantity'];
          final attrs =
              (row['attributes'] as List?)
                  ?.map(
                    (a) => a is Map
                        ? (a['value'] ?? a['name'] ?? a.toString())
                        : a.toString(),
                  )
                  .where((x) => x != null)
                  .join(' • ') ??
              '';
          final attrsPart = attrs.isNotEmpty ? ' — $attrs' : '';
          return '- $name$size$color$attrsPart (السعر: $price, الكمية: $qty)';
        })
        .join('\n');

    return 'بالتأكيد، وجدت $count منتج(ات):\n$products';
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
        screen = SettingsHomeScreen() as Widget;
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
      case 'last_week':
        final monday = now.subtract(Duration(days: (now.weekday - 1) + 7));
        start = DateTime(monday.year, monday.month, monday.day);
        end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'last_month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'today':
      default:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    final sIso = start.toIso8601String();
    final eIso = end.toIso8601String();

    if (a.metric == MetricType.returns) {
      final total = await _sumRefunds(sIso, eIso);
      return 'بكل سرور، قيمة المرتجعات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == MetricType.sales) {
      final total = await _sumSales(sIso, eIso);
      return 'تمام، إجمالي المبيعات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == MetricType.expenses) {
      final total = await reportsRepo.expensesTotalByDate(
        startIso: sIso,
        endIso: eIso,
      );
      return 'بكل عناية، إجمالي المصروفات ${total.toStringAsFixed(2)}.';
    }
    if (a.metric == MetricType.profit) {
      final sales = await _sumSales(sIso, eIso);
      final purchases = await reportsRepo.purchasesTotalByDate(
        startIso: sIso,
        endIso: eIso,
      );
      final expenses = await reportsRepo.expensesTotalByDate(
        startIso: sIso,
        endIso: eIso,
      );
      final profit = sales - purchases - expenses;
      return 'على الرحب والسعة، صافي الأرباح ${profit.toStringAsFixed(2)}.';
    }
    return 'لا يمكنني قياس هذا المقياس بعد.';
  }

  Future<double> _sumRefunds(String startIso, String endIso) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM payments
      WHERE method = 'REFUND'
        AND datetime(created_at) >= datetime(?)
        AND datetime(created_at) <= datetime(?)
      ''',
      [startIso, endIso],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> _sumSales(String startIso, String endIso) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT SUM(si.quantity * si.price_per_unit) AS total
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      WHERE datetime(s.sale_date) >= datetime(?) AND datetime(s.sale_date) <= datetime(?) 
      ''',
      [startIso, endIso],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
