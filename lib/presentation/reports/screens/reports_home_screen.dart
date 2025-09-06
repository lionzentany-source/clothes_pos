import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'reports_dashboard_screen.dart';
import 'customers_report_screen.dart';
import 'users_variance_notes_report_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/expenses/screens/expense_list_screen.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  int _selectedNavIndex = 0;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('التقارير')),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;

            // قائمة أقسام التقارير
            final navItems = [
              _NavItem(
                title: 'لوحة التقارير',
                subtitle: 'التقارير التفاعلية والرسوم البيانية',
                icon: CupertinoIcons.chart_bar,
                builder: (_) => const ReportsDashboardScreen(),
              ),
              _NavItem(
                title: 'تقرير المبيعات',
                subtitle: 'تفاصيل المبيعات والأرباح اليومية',
                icon: CupertinoIcons.money_dollar_circle,
                builder: (_) => const ReportsDashboardScreen(),
              ),
              _NavItem(
                title: 'تقرير المخزون',
                subtitle: 'حالة المخزون والمنتجات الحالية',
                icon: CupertinoIcons.cube_box,
                builder: (_) => const InventoryListScreen(),
              ),
              _NavItem(
                title: 'تقرير المصروفات',
                subtitle: 'تفاصيل المصروفات والتكاليف',
                icon: CupertinoIcons.minus_circle,
                builder: (_) => const ExpenseListScreen(),
              ),
              _NavItem(
                title: 'تقرير العملاء',
                subtitle: 'إحصائيات العملاء والمبيعات',
                icon: CupertinoIcons.person_2,
                builder: (_) => const CustomersReportScreen(),
              ),
              _NavItem(
                title: 'ملاحظات فرق الكاش',
                subtitle: 'ملاحظات فرق الكاش عند إغلاق الجلسات',
                icon: CupertinoIcons.exclamationmark_bubble,
                builder: (_) => const UsersVarianceNotesReportScreen(),
              ),
              _NavItem(
                title: 'تقرير الأداء',
                subtitle: 'إحصائيات الأداء والمبيعات الشهرية',
                icon: CupertinoIcons.chart_pie,
                builder: (_) => const Center(
                  child: Text(
                    'قريباً - تقرير الأداء الشهري',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ),
              _NavItem(
                title: 'تقرير الضرائب',
                subtitle: 'تقارير الضرائب والمبيعات الخاضعة للضريبة',
                icon: CupertinoIcons.doc_text,
                builder: (_) => const Center(
                  child: Text(
                    'قريباً - تقرير الضرائب',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ),
            ];

            Widget navListBuilder() {
              return Column(
                children: [
                  // الإحصائيات السريعة في الأعلى
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إحصائيات سريعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                title: 'المبيعات اليوم',
                                value: '0.00',
                                icon: CupertinoIcons.money_dollar,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatCard(
                                title: 'عدد الفواتير',
                                value: '0',
                                icon: CupertinoIcons.doc_text,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        return Column(
                          children: [
                            _NavButton(
                              title: item.title,
                              subtitle: item.subtitle,
                              icon: item.icon,
                              selected: isWide && _selectedNavIndex == index,
                              onPressed: () {
                                if (isWide) {
                                  setState(() => _selectedNavIndex = index);
                                } else {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => item.builder(context),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            Widget buildDetail(int index) {
              if (index < 0 || index >= navItems.length) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar,
                        size: 64,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اختر تقريراً من القائمة الجانبية',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return navItems[index].builder(context);
            }

            if (isWide) {
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: buildDetail(_selectedNavIndex),
                    ),
                  ),
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.colors.border),
                      ),
                      color: context.colors.surfaceAlt,
                    ),
                    child: navListBuilder(),
                  ),
                ],
              );
            }

            return navListBuilder();
          },
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  _NavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

/// زر الملاحة المستخدم في القائمة الجانبية
class _NavButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _NavButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? context.colors.surface : Colors.transparent;
    final textColor = selected
        ? context.colors.textPrimary
        : context.colors.textPrimary;
    final iconColor = selected
        ? context.colors.primary
        : context.colors.textSecondary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: context.colors.border.withValues(alpha: 0.3))
              : null,
        ),
        child: AppTextButton(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
