import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';

/// شاشة لوحة التقارير - تعرض الرسوم البيانية والإحصائيات
class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final _reportsRepo = sl<ReportsRepository>();

  // حالة التحميل
  bool _isLoading = false;

  // فلاتر التاريخ
  DateTime? _startDate;
  DateTime? _endDate;

  // بيانات المبيعات
  List<Map<String, Object?>> _salesData = [];

  // بيانات المنتجات الأكثر مبيعًا
  List<Map<String, Object?>> _topProductsData = [];

  // بيانات المبيعات حسب الفئة
  List<Map<String, Object?>> _salesByCategoryData = [];

  @override
  void initState() {
    super.initState();
    _initializeDateRange();
    _loadData();
  }

  /// تهيئة نطاق التاريخ الافتراضي (آخر 30 يوم)
  void _initializeDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day - 30);
    _endDate = now;
  }

  /// تحميل بيانات التقارير
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل بيانات المبيعات اليومية
      _salesData = await _reportsRepo.salesByDay(
        startIso: _startDate?.toIso8601String(),
        endIso: _endDate?.toIso8601String(),
      );

      // تحميل بيانات المنتجات الأكثر مبيعًا
      _topProductsData = await _reportsRepo.topProducts(
        startIso: _startDate?.toIso8601String(),
        endIso: _endDate?.toIso8601String(),
        limit: 5,
      );

      // تحميل بيانات المبيعات حسب الفئة
      _salesByCategoryData = await _reportsRepo.salesByCategory(
        startIso: _startDate?.toIso8601String(),
        endIso: _endDate?.toIso8601String(),
      );
    } catch (e) {
      // في حالة الخطأ، نعرض رسالة للمستخدم
      if (mounted) {
        _showErrorDialog('فشل في تحميل البيانات: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// عرض رسالة خطأ
  void _showErrorDialog(String message) {
    if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// بناء شريط الفلاتر
  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // فلتر التاريخ
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
              onPressed: _showDatePicker,
              child: Text(
                _startDate != null && _endDate != null
                    ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                    : 'اختر التاريخ',
                style: const TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر التحديث
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _isLoading ? null : _loadData,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : const Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.systemBlue,
                  ),
          ),
        ],
      ),
    );
  }

  /// عرض منتقي التاريخ
  void _showDatePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: _startDate ?? DateTime.now(),
            mode: CupertinoDatePickerMode.date,
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDate) {
              setState(() {
                _startDate = newDate;
                _endDate = newDate.add(const Duration(days: 30));
              });
              _loadData();
            },
          ),
        ),
      ),
    );
  }

  /// تنسيق التاريخ للعرض
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// بناء منطقة المحتوى الرئيسي
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تحميل البيانات...',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الإحصائيات السريعة
            _buildQuickStatsCard(),
            const SizedBox(height: 20),

            // منطقة الرسوم البيانية
            _buildChartsSection(),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة الإحصائيات السريعة
  Widget _buildQuickStatsCard() {
    final totalSales = _salesData.fold<double>(
      0,
      (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
    );

    final totalTransactions = _salesData.fold<int>(
      0,
      (sum, item) => sum + ((item['invoice_count'] as num?)?.toInt() ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات سريعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'إجمالي المبيعات',
                  '${totalSales.toStringAsFixed(2)} ر.س',
                  CupertinoIcons.money_dollar,
                  CupertinoColors.systemGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'عدد المعاملات',
                  '$totalTransactions',
                  CupertinoIcons.doc_text,
                  CupertinoColors.systemBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'متوسط القيمة',
                  '${(totalTransactions > 0 ? totalSales / totalTransactions : 0).toStringAsFixed(2)} ر.س',
                  CupertinoIcons.arrow_up_right,
                  CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر إحصائية واحد
  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم الرسوم البيانية
  Widget _buildChartsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرسوم البيانية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // مخطط المبيعات حسب الأيام
          if (_salesData.isNotEmpty) ...[
            const Text(
              'المبيعات حسب الأيام',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: _buildLineChart(),
            ),
            const SizedBox(height: 20),
          ],

          // مخطط المبيعات حسب الفئات
          if (_salesByCategoryData.isNotEmpty) ...[
            const Text(
              'المبيعات حسب الفئات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: _buildBarChart(),
            ),
            const SizedBox(height: 20),
          ],

          // مخطط المنتجات الأكثر مبيعًا
          if (_topProductsData.isNotEmpty) ...[
            const Text(
              'المنتجات الأكثر مبيعًا',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: _buildPieChart(),
            ),
          ],

          if (_salesData.isEmpty &&
              _salesByCategoryData.isEmpty &&
              _topProductsData.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chart_bar,
                    size: 48,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد بيانات لعرضها',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// بناء مخطط خطي للمبيعات حسب الأيام
  Widget _buildLineChart() {
    final salesSpots = <FlSpot>[];
    double maxX = 0;
    double maxY = 0;

    for (int i = 0; i < _salesData.length; i++) {
      final item = _salesData[i];
      final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;
      salesSpots.add(FlSpot(i.toDouble(), amount));

      if (i > maxX) maxX = i.toDouble();
      if (amount > maxY) maxY = amount;
    }

    // ضمان وجود قيمة maxY صحيحة
    if (maxY == 0) maxY = 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _salesData.length) {
                  final dateStr =
                      _salesData[value.toInt()]['sale_date'] as String?;
                  if (dateStr != null) {
                    final date = DateTime.parse(dateStr);
                    return Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    );
                  }
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.secondaryLabel,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.1, // إضافة هامش علوي
        lineBarsData: [
          LineChartBarData(
            spots: salesSpots,
            isCurved: true,
            color: CupertinoColors.systemBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: CupertinoColors.systemBlue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء مخطط عمودي للمبيعات حسب الفئات
  Widget _buildBarChart() {
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < _salesByCategoryData.length; i++) {
      final item = _salesByCategoryData[i];
      final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: _getColorFromIndex(i),
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );

      if (amount > maxY) maxY = amount;
    }

    // ضمان وجود قيمة maxY صحيحة
    if (maxY == 0) maxY = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2, // إضافة هامش علوي
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                CupertinoColors.systemGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = _salesByCategoryData[groupIndex];
              final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;

              return BarTooltipItem(
                '$groupIndex\n',
                const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '${amount.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _salesByCategoryData.length) {
                  final categoryName =
                      (_salesByCategoryData[value.toInt()]['category_name']
                          as String?) ??
                      'غير محدد';
                  // تقليص اسم الفئة إذا كان طويلًا جدًا
                  String displayText = categoryName;
                  if (displayText.length > 10) {
                    displayText = '${displayText.substring(0, 10)}...';
                  }
                  return Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.secondaryLabel,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
          ),
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
        ),
      ),
    );
  }

  /// بناء مخطط دائري للمنتجات الأكثر مبيعًا
  Widget _buildPieChart() {
    final sections = <PieChartSectionData>[];

    double total = 0;
    for (final item in _topProductsData) {
      total += (item['total_amount'] as num?)?.toDouble() ?? 0;
    }

    if (total == 0) {
      return const Center(
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      );
    }

    for (int i = 0; i < _topProductsData.length; i++) {
      final item = _topProductsData[i];
      final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;
      final percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: _getColorFromIndex(i),
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
            // يمكن إضافة تفاعل عند اللمس هنا
          },
        ),
      ),
    );
  }

  /// الحصول على لون بناءً على الفهرس
  Color _getColorFromIndex(int index) {
    const List<Color> colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemRed,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('لوحة التقارير'),
      ),
      child: SafeArea(
        child: Column(children: [_buildFiltersBar(), _buildMainContent()]),
      ),
    );
  }
}
