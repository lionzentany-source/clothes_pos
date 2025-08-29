import 'package:flutter/cupertino.dart';
import 'reports_dashboard_screen.dart';
import 'customers_report_screen.dart';
import 'users_variance_notes_report_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/expenses/screens/expense_list_screen.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  /// الانتقال إلى تقرير العملاء
  void _showCustomersReportDialog(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const CustomersReportScreen()),
    );
  }

  /// الانتقال إلى تقرير ملاحظات فرق الكاش
  void _showUsersVarianceNotesReport(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const UsersVarianceNotesReportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('التقارير')),
      child: SafeArea(
        child: Column(
          children: [
            // Quick stats cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildReportTile(
                      title: 'ملاحظات فرق الكاش للمستخدمين',
                      subtitle:
                          'عرض جميع ملاحظات فرق الكاش المسجلة عند إغلاق الجلسات',
                      icon: CupertinoIcons.exclamationmark_bubble,
                      onTap: () {
                        _showUsersVarianceNotesReport(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'المبيعات اليوم',
                      value: '0.00',
                      icon: CupertinoIcons.money_dollar,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'عدد الفواتير',
                      value: '0',
                      icon: CupertinoIcons.doc_text,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Reports menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildReportTile(
                    title: 'لوحة التقارير',
                    subtitle: 'عرض التقارير التفاعلية والرسوم البيانية',
                    icon: CupertinoIcons.chart_bar,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ReportsDashboardScreen(),
                        ),
                      );
                    },
                  ),

                  _buildReportTile(
                    title: 'تقرير المبيعات',
                    subtitle: 'تفاصيل المبيعات والأرباح',
                    icon: CupertinoIcons.money_dollar_circle,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ReportsDashboardScreen(),
                        ),
                      );
                    },
                  ),

                  _buildReportTile(
                    title: 'تقرير المخزون',
                    subtitle: 'حالة المخزون والمنتجات',
                    icon: CupertinoIcons.cube_box,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const InventoryListScreen(),
                        ),
                      );
                    },
                  ),

                  _buildReportTile(
                    title: 'تقرير المصروفات',
                    subtitle: 'تفاصيل المصروفات والتكاليف',
                    icon: CupertinoIcons.minus_circle,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ExpenseListScreen(),
                        ),
                      );
                    },
                  ),

                  _buildReportTile(
                    title: 'تقرير العملاء',
                    subtitle: 'إحصائيات العملاء والمبيعات',
                    icon: CupertinoIcons.person_2,
                    onTap: () {
                      _showCustomersReportDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: CupertinoColors.systemBlue, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          color: CupertinoColors.systemGrey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
