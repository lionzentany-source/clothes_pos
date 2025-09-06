import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_rfid_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/stocktake_screen.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';
import 'package:clothes_pos/presentation/inventory/screens/product_editor_screen.dart';
import 'package:clothes_pos/presentation/purchases/screens/purchase_editor_screen.dart';
import 'package:clothes_pos/presentation/categories/screens/categories_management_screen.dart';
import 'package:clothes_pos/presentation/brands/screens/brands_management_screen.dart';
import 'package:clothes_pos/presentation/suppliers/screens/suppliers_management_screen.dart';
import 'package:clothes_pos/core/di/locator.dart';

class InventoryHomeScreen extends StatefulWidget {
  const InventoryHomeScreen({super.key});

  @override
  State<InventoryHomeScreen> createState() => _InventoryHomeScreenState();
}

class _InventoryHomeScreenState extends State<InventoryHomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('المخزون')),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;

            // قائمة أقسام المخزون
            final navItems = [
              _NavItem(
                title: 'قائمة المنتجات',
                subtitle: 'عرض وإدارة جميع المنتجات',
                icon: CupertinoIcons.cube_box,
                builder: (_) => BlocProvider(
                  create: (_) => sl<InventoryCubit>()..load(),
                  child: const InventoryListScreen(),
                ),
              ),
              _NavItem(
                title: 'الجرد',
                subtitle: 'تنفيذ عمليات الجرد والتحقق',
                icon: CupertinoIcons.checkmark_rectangle,
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => sl<StocktakeCubit>()),
                    BlocProvider(create: (_) => sl<StocktakeRfidCubit>()),
                  ],
                  child: const StocktakeScreen(),
                ),
              ),
              _NavItem(
                title: 'إضافة منتج جديد',
                subtitle: 'إنشاء منتج جديد في المخزون',
                icon: CupertinoIcons.add_circled,
                builder: (_) => const ProductEditorScreen(),
              ),
              _NavItem(
                title: 'إنشاء فاتورة شراء',
                subtitle: 'إضافة مشتريات جديدة للمخزون',
                icon: CupertinoIcons.doc_text_fill,
                builder: (_) => const PurchaseEditorScreen(),
              ),
              _NavItem(
                title: 'التصنيفات',
                subtitle: 'إدارة تصنيفات المنتجات',
                icon: CupertinoIcons.tags,
                builder: (_) => const CategoriesManagementScreen(),
              ),
              _NavItem(
                title: 'العلامات التجارية',
                subtitle: 'إدارة العلامات التجارية',
                icon: CupertinoIcons.star_circle,
                builder: (_) => const BrandsManagementScreen(),
              ),
              _NavItem(
                title: 'الموردين',
                subtitle: 'إدارة الموردين والشركات',
                icon: CupertinoIcons.building_2_fill,
                builder: (_) => const SuppliersManagementScreen(),
              ),
              _NavItem(
                title: 'تقارير المخزون',
                subtitle: 'إحصائيات وتقارير المخزون',
                icon: CupertinoIcons.chart_bar_alt_fill,
                builder: (_) => BlocProvider(
                  create: (_) => sl<InventoryCubit>()..load(),
                  child: const _InventoryReportsScreen(),
                ),
              ),
            ];

            Widget navListBuilder() {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
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
                        CupertinoIcons.cube_box,
                        size: 64,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اختر قسماً من القائمة الجانبية',
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

/// شاشة تقارير المخزون
class _InventoryReportsScreen extends StatelessWidget {
  const _InventoryReportsScreen();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text('تقارير المخزون'),
          trailing: AppIconButton(
            onPressed: () {
              // تحديث التقارير
              context.read<InventoryCubit>().load();
            },
            icon: const Icon(CupertinoIcons.refresh),
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state.loading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                );
              }

              // حساب الإحصائيات
              final totalProducts = state.items.length;
              final totalQuantity = state.items.fold<int>(
                0,
                (sum, item) => sum + item.variant.quantity,
              );
              final lowStockItems = state.items
                  .where((item) => item.isLowStock)
                  .length;
              final totalValue = state.items.fold<double>(
                0.0,
                (sum, item) =>
                    sum + (item.variant.quantity * item.variant.salePrice),
              );

              return SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إحصائيات عامة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // بطاقات الإحصائيات
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'إجمالي المنتجات',
                                value: totalProducts.toString(),
                                icon: CupertinoIcons.cube_box,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'إجمالي الكمية',
                                value: totalQuantity.toString(),
                                icon: CupertinoIcons.number,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'قليل المخزون',
                                value: lowStockItems.toString(),
                                icon: CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'قيمة المخزون',
                                value: '${totalValue.toStringAsFixed(2)} ج.م',
                                icon: CupertinoIcons.money_dollar,
                                color: CupertinoColors.systemPurple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        if (lowStockItems > 0) ...[
                          Text(
                            'منتجات قليلة المخزون',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemRed.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                for (final item in state.items.where(
                                  (item) => item.isLowStock,
                                ))
                                  CupertinoListTile(
                                    title: Text(
                                      item.parentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'الكمية المتبقية: ${item.variant.quantity}',
                                    ),
                                    trailing: const Icon(
                                      CupertinoIcons
                                          .exclamationmark_triangle_fill,
                                      color: CupertinoColors.systemRed,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// بطاقة إحصائية
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
