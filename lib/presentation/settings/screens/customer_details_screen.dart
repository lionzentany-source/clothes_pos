import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/common/money.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('تفاصيل العميل')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  fontSize: AppTypography.fs18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'رقم الهاتف: ${customer.phoneNumber ?? 'غير متوفر'}',
                style: const TextStyle(
                  fontSize: AppTypography.fs16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'سجل المشتريات:',
                style: TextStyle(
                  fontSize: AppTypography.fs16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: FutureBuilder<List<Map<String, Object?>>>(
                  future: sl<SalesRepository>().salesForCustomer(customer.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('لا توجد مشتريات لهذا العميل'),
                      );
                    }
                    final sales = snapshot.data!;
                    return ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (context, i) => Container(
                        height: 0.5,
                        color: CupertinoColors.separator,
                      ),
                      itemBuilder: (context, i) {
                        final sale = sales[i];
                        final date = DateTime.parse(
                          sale['sale_date'] as String,
                        );
                        return CupertinoListTile(
                          title: Text('فاتورة رقم: ${sale['id']}'),
                          subtitle: Text(
                            'تاريخ: ${date.day}/${date.month}/${date.year}',
                          ),
                          trailing: Text(
                            money(
                              context,
                              (sale['total_amount'] as num).toDouble(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
