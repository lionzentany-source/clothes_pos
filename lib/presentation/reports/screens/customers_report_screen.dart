import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/customer_repository.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class CustomersReportScreen extends StatefulWidget {
  const CustomersReportScreen({super.key});

  @override
  State<CustomersReportScreen> createState() => _CustomersReportScreenState();
}

class _CustomersReportScreenState extends State<CustomersReportScreen> {
  final _customerRepo = sl<CustomerRepository>();

  List<Map<String, Object?>> _customersStats = [];
  bool _loading = true;
  int _totalCustomers = 0;
  double _totalRevenue = 0;
  int _activeCustomers = 0;

  Future<void> _loadCustomersStats() async {
    try {
      setState(() => _loading = true);

      // Get customers with sales statistics
      final stats = await _customerRepo.getCustomersWithSalesStats(limit: 100);
      final totalCustomers = await _customerRepo.getCount();

      // Calculate summary statistics
      double totalRevenue = 0;
      int activeCustomers = 0;

      for (final stat in stats) {
        final totalSpent = (stat['total_spent'] as num?)?.toDouble() ?? 0;
        final totalSales = (stat['total_sales'] as num?)?.toInt() ?? 0;

        totalRevenue += totalSpent;
        if (totalSales > 0) activeCustomers++;
      }

      if (mounted) {
        setState(() {
          _customersStats = stats;
          _totalCustomers = totalCustomers;
          _totalRevenue = totalRevenue;
          _activeCustomers = activeCustomers;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load customers stats', error: e);
      if (mounted) {
        setState(() => _loading = false);
        _showErrorDialog('فشل في تحميل إحصائيات العملاء', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Text(message),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color ?? CupertinoColors.activeBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.fs14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('تقرير العملاء'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loading ? null : _loadCustomersStats,
          child: _loading
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: (_loading && _totalCustomers == 0)
            ? const Center(child: Text('لا يوجد عملاء مسجلين'))
            : Column(
                children: [
                  // Summary statistics
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'إجمالي العملاء',
                                value: _totalCustomers.toString(),
                                icon: CupertinoIcons.person_2,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _buildStatCard(
                                title: 'العملاء النشطين',
                                value: _activeCustomers.toString(),
                                icon: CupertinoIcons.person_fill,
                                color: CupertinoColors.activeGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildStatCard(
                          title: 'إجمالي الإيرادات من العملاء',
                          value: money(context, _totalRevenue),
                          icon: CupertinoIcons.money_dollar,
                          color: CupertinoColors.systemGreen,
                        ),
                      ],
                    ),
                  ),
                  // Section title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'أفضل العملاء',
                          style: TextStyle(
                            fontSize: AppTypography.fs18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_customersStats.length} عميل',
                          style: const TextStyle(
                            fontSize: AppTypography.fs14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Customers list
                  Expanded(
                    child: _customersStats.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.person_2,
                                  size: 64,
                                  color: CupertinoColors.systemGrey,
                                ),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  'لا توجد بيانات عملاء',
                                  style: TextStyle(
                                    fontSize: AppTypography.fs16,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: _customersStats.length,
                            separatorBuilder: (context, index) => Container(
                              height: 0.5,
                              color: CupertinoColors.separator,
                            ),
                            itemBuilder: (context, index) {
                              final customer = _customersStats[index];
                              final name =
                                  customer['name'] as String? ?? 'غير محدد';
                              final phone = customer['phone_number'] as String?;
                              final totalSales =
                                  (customer['total_sales'] as num?)?.toInt() ??
                                  0;
                              final totalSpent =
                                  (customer['total_spent'] as num?)
                                      ?.toDouble() ??
                                  0;
                              final lastSaleDate =
                                  customer['last_sale_date'] as String?;
                              String lastSaleText = 'لا توجد مشتريات';
                              if (lastSaleDate != null) {
                                try {
                                  final date = DateTime.parse(lastSaleDate);
                                  lastSaleText =
                                      '${date.day}/${date.month}/${date.year}';
                                } catch (e) {
                                  lastSaleText = 'تاريخ غير صحيح';
                                }
                              }
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    // Customer rank
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: index < 3
                                            ? CupertinoColors.systemYellow
                                                  .withOpacity(0.2)
                                            : CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: AppTypography.fs14,
                                            fontWeight: FontWeight.bold,
                                            color: index < 3
                                                ? CupertinoColors.systemYellow
                                                : CupertinoColors.systemGrey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    // Customer info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: AppTypography.fs16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (phone != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              phone,
                                              style: const TextStyle(
                                                fontSize: AppTypography.fs14,
                                                color:
                                                    CupertinoColors.systemGrey,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            'آخر شراء: $lastSaleText',
                                            style: const TextStyle(
                                              fontSize: AppTypography.fs12,
                                              color:
                                                  CupertinoColors.systemGrey2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Sales stats
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          money(context, totalSpent),
                                          style: const TextStyle(
                                            fontSize: AppTypography.fs16,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.systemGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$totalSales مشتريات',
                                          style: const TextStyle(
                                            fontSize: AppTypography.fs12,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
