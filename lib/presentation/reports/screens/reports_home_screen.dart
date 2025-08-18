import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/common/money.dart';

import 'package:clothes_pos/data/repositories/category_repository.dart';

import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';

import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/presentation/purchases/screens/supplier_search_page.dart';
import 'package:clothes_pos/core/printing/reports_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  final _repo = sl<ReportsRepository>();
  bool _loading = true;
  List<Map<String, Object?>> byDay = [];
  List<Map<String, Object?>> byMonth = [];
  List<Map<String, Object?>> top = [];
  List<Map<String, Object?>> staff = [];
  List<Map<String, Object?>> stock = [];
  double purchasesTotal = 0;
  double expensesTotal = 0;
  DateTime? start;
  DateTime? end;
  double _stockThreshold = 0;

  AppUser? selectedUser;
  Category? selectedCategory;
  Supplier? selectedSupplier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _netAfterExpenses() {
    // sales total approximation: sum of byDay totals
    final sales = byDay.fold<double>(
      0.0,
      (p, e) => p + ((e['total'] as num?)?.toDouble() ?? 0),
    );
    return sales - purchasesTotal - expensesTotal;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load stock low threshold from settings
      final thrStr = await sl<SettingsRepository>().get('stock_low_threshold');
      _stockThreshold = double.tryParse(thrStr ?? '0') ?? 0;

      final startIso = start?.toIso8601String();
      final endIso = end?.toIso8601String();
      final userId = selectedUser?.id;
      final categoryId = selectedCategory?.id;
      final supplierId = selectedSupplier?.id;

      byDay = await _repo.salesByDay(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
        supplierId: supplierId,
      );
      byMonth = await _repo.salesByMonth(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
        supplierId: supplierId,
      );
      top = await _repo.topProducts(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
        supplierId: supplierId,
      );
      staff = await _repo.employeePerformance(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
      );
      stock = await _repo.stockStatus(
        categoryId: categoryId,
        supplierId: supplierId,
      );
      purchasesTotal = await _repo.purchasesTotalByDate(
        startIso: startIso,
        endIso: endIso,
        supplierId: supplierId,
      );
      expensesTotal = await _repo.expensesTotalByDate(
        startIso: startIso,
        endIso: endIso,
        categoryId: null, // could be filtered later
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickUser() async {
    final users = await sl<AuthRepository>().listActiveUsers();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    void safePop([Object? r]) {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop(r);
    }

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(l.pickEmployee),
        actions: [
          for (final u in users)
            CupertinoActionSheetAction(
              onPressed: () {
                safePop();
                setState(() => selectedUser = u);
                _load();
              },
              child: Text(
                u.fullName?.isNotEmpty == true ? u.fullName! : u.username,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => safePop(),
          isDefaultAction: true,
          child: Text(l.cancel),
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final cats = await sl<CategoryRepository>().listAll(limit: 200);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    void safePop([Object? r]) {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop(r);
    }

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(l.pickCategory),
        actions: [
          for (final c in cats)
            CupertinoActionSheetAction(
              onPressed: () {
                safePop();
                setState(() => selectedCategory = c);
                _load();
              },
              child: Text(c.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => safePop(),
          isDefaultAction: true,
          child: Text(l.cancel),
        ),
      ),
    );
  }

  Future<void> _pickSupplier() async {
    final selected = await Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const SupplierSearchPage()));
    if (selected != null) {
      setState(() => selectedSupplier = selected);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canView =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.viewReports,
        ) ??
        false;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView) ? null : _load,
          child: const Icon(CupertinoIcons.refresh),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView)
              ? null
              : () async {
                  final l = AppLocalizations.of(context)!;
                  final service = ReportsPdfService();
                  final file = await service.generate(
                    byDay: byDay,
                    byMonth: byMonth,
                    topProducts: top,
                    staffPerf: staff,
                    stockStatus: stock,
                    purchasesTotal: purchasesTotal,
                    locale: context.read<SettingsCubit>().state.localeCode,
                    title: l.reportsTitle,
                    dailySalesLabel: l.dailySales90,
                    monthlySalesLabel: l.monthlySales24,
                    topProductsLabel: l.topProductsQty,
                    staffPerformanceLabel: l.staffPerformance,
                    purchasesTotalLabel: l.purchasesTotalPeriod,
                    stockStatusLabel: l.stockStatusLowFirst,
                    skuPattern: 'SKU {sku}: {qty} — RP {rp}',
                  );
                  await Printing.sharePdf(
                    bytes: await file.readAsBytes(),
                    filename: 'reports.pdf',
                  );
                },
          child: const Icon(CupertinoIcons.doc),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView)
              ? null
              : () async {
                  final now = DateTime.now();
                  final pickedStart = await showCupertinoModalPopup<DateTime?>(
                    context: context,
                    builder: (_) => _DatePickerSheet(initial: start ?? now),
                  );
                  if (pickedStart != null) {
                    start = pickedStart;
                    await _load();
                  }
                },
          child: const Icon(CupertinoIcons.calendar),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView)
              ? null
              : () async {
                  final now = DateTime.now();
                  final pickedEnd = await showCupertinoModalPopup<DateTime?>(
                    context: context,
                    builder: (_) => _DatePickerSheet(initial: end ?? now),
                  );
                  if (pickedEnd != null) {
                    setState(() => end = pickedEnd);
                    await _load();
                  }
                },
          child: const Icon(CupertinoIcons.calendar_badge_minus),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView) ? null : _pickUser,
          child: const Icon(CupertinoIcons.person),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView) ? null : _pickCategory,
          child: const Icon(CupertinoIcons.tag),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView) ? null : _pickSupplier,
          child: const Icon(CupertinoIcons.person_2),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_loading || !canView)
              ? null
              : () async {
                  setState(() {
                    start = null;
                    end = null;
                    selectedUser = null;
                    selectedCategory = null;
                    selectedSupplier = null;
                  });
                  await _load();
                },
          child: const Icon(CupertinoIcons.clear_circled),
        ),
      ],
    );

    final content = <Widget>[];
    if (!canView) {
      content.addAll(const [
        ViewOnlyBanner(
          message: 'عرض فقط: لا تملك صلاحية عرض التقارير',
          margin: EdgeInsets.only(bottom: 12),
        ),
        Text(
          '— لا تتوفر بيانات لعدم امتلاك الصلاحية —',
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 20),
      ]);
    }
    if (canView) {
      content.addAll([
        _sectionHeader(AppLocalizations.of(context)!.dailySales90),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 2,
                  color: CupertinoColors.activeBlue,
                  dotData: const FlDotData(show: false),
                  spots: [
                    for (int i = 0; i < byDay.length; i++)
                      FlSpot(
                        i.toDouble(),
                        ((byDay[i]['total'] as num?)?.toDouble() ?? 0.0),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final r in byDay)
          Text(
            '${r['d']}: ${r['cnt']} — ${money(context, (r['total'] as num?)?.toDouble() ?? 0)}',
          ),
        const SizedBox(height: 16),
        _sectionHeader(AppLocalizations.of(context)!.monthlySales24),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < byMonth.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: ((byMonth[i]['total'] as num?)?.toDouble() ?? 0.0),
                        color: CupertinoColors.activeGreen,
                        width: 10,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final r in byMonth)
          Text(
            '${r['m']}: ${r['cnt']} — ${money(context, (r['total'] as num?)?.toDouble() ?? 0)}',
          ),
        const SizedBox(height: 16),
        _sectionHeader(AppLocalizations.of(context)!.topProductsQty),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < top.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: ((top[i]['qty'] as num?)?.toDouble() ?? 0.0),
                        color: CupertinoColors.systemIndigo,
                        width: 10,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final r in top)
          Text(
            'SKU ${r['sku']}: ${r['qty']} — ${money(context, (r['rev'] as num?)?.toDouble() ?? 0)}',
          ),
        const SizedBox(height: 16),
        _sectionHeader(AppLocalizations.of(context)!.staffPerformance),
        for (final r in staff)
          Text(
            '${r['username']}: ${r['cnt']} — ${money(context, (r['total'] as num?)?.toDouble() ?? 0)}',
          ),
        const SizedBox(height: 16),
        _sectionHeader(AppLocalizations.of(context)!.purchasesTotalPeriod),
        Text(money(context, purchasesTotal)),
        const SizedBox(height: 12),
        _sectionHeader('إجمالي المصروفات للفترة'),
        Text(money(context, expensesTotal)),
        const SizedBox(height: 12),
        _sectionHeader('صافي بعد المصروفات (مبيعات - مشتريات - مصروفات)'),
        Text(money(context, _netAfterExpenses())),
        const SizedBox(height: 16),
        _sectionHeader(AppLocalizations.of(context)!.stockStatusLowFirst),
        for (final r in stock)
          Builder(
            builder: (context) {
              final qty = (r['quantity'] as num?)?.toDouble() ?? 0;
              final isLow = qty <= _stockThreshold;
              return Row(
                children: [
                  if (isLow)
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 16,
                      color: CupertinoColors.systemRed,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'SKU ${r['sku']}: ${r['quantity']} — RP ${r['reorder_point']}',
                    style: TextStyle(
                      color: isLow
                          ? CupertinoColors.systemRed
                          : CupertinoColors.label,
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 60),
      ]);
    }

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(AppLocalizations.of(context)!.reportsTitle),
            trailing: actions,
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                sliver: SliverList(delegate: SliverChildListDelegate(content)),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _sectionHeader(String text) => Padding(
  padding: const EdgeInsets.only(top: 8, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
);

class _DatePickerSheet extends StatelessWidget {
  final DateTime initial;
  const _DatePickerSheet({required this.initial});
  @override
  Widget build(BuildContext context) {
    DateTime selected = initial;
    final l = AppLocalizations.of(context)!;
    void safePop([Object? r]) {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop(r);
    }

    return Container(
      color: CupertinoColors.systemGroupedBackground,
      height: 300,
      child: Column(
        children: [
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              onDateTimeChanged: (d) => selected = d,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(l.cancel),
                onPressed: () => safePop(),
              ),
              CupertinoButton(
                child: Text(l.datePickerSelect),
                onPressed: () => safePop(selected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
