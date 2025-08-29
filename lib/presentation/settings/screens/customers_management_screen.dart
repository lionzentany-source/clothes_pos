import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/data/repositories/customer_repository.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'customer_details_screen.dart';

class CustomersManagementScreen extends StatefulWidget {
  const CustomersManagementScreen({super.key});

  @override
  State<CustomersManagementScreen> createState() =>
      _CustomersManagementScreenState();
}

class _CustomersManagementScreenState extends State<CustomersManagementScreen> {
  final _customerRepo = sl<CustomerRepository>();
  final _searchController = TextEditingController();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customers);
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              (customer.phoneNumber?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _loading = true);
      final customers = await _customerRepo.listAll(limit: 1000);
      if (mounted) {
        setState(() {
          _customers = customers;
          _filteredCustomers = List.from(customers);
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load customers', error: e);
      if (mounted) {
        setState(() => _loading = false);
        _showErrorDialog('فشل في تحميل قائمة العملاء', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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

  Future<void> _showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoTextField(
                      controller: nameController,
                      placeholder: 'اسم العميل',
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoTextField(
                      controller: phoneController,
                      placeholder: 'رقم الهاتف (اختياري)',
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('إضافة'),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              try {
                final customer = Customer(
                  name: name,
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                final userId = context.read<AuthCubit>().state.user?.id;
                await _customerRepo.create(customer, userId: userId);

                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog('فشل في إضافة العميل', e.toString());
                }
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCustomers();
    }
  }

  Future<void> _showEditCustomerDialog(Customer customer) async {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(
      text: customer.phoneNumber ?? '',
    );

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تعديل بيانات العميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoTextField(
                      controller: nameController,
                      placeholder: 'اسم العميل',
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoTextField(
                      controller: phoneController,
                      placeholder: 'رقم الهاتف (اختياري)',
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('حفظ'),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              try {
                final updatedCustomer = customer.copyWith(
                  name: name,
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                final userId = context.read<AuthCubit>().state.user?.id;
                await _customerRepo.update(updatedCustomer, userId: userId);

                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog('فشل في تحديث بيانات العميل', e.toString());
                }
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCustomers();
    }
  }

  Future<void> _showDeleteCustomerDialog(Customer customer) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('حذف العميل'),
        content: Text(
          'هل أنت متأكد من حذف العميل "${customer.name}"؟\n\nسيتم الاحتفاظ بسجل مشترياته السابقة.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('حذف'),
            onPressed: () async {
              try {
                final userId = context.read<AuthCubit>().state.user?.id;
                await _customerRepo.delete(customer.id!, userId: userId);

                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog('فشل في حذف العميل', e.toString());
                }
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canManage =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.manageCustomers,
        ) ??
        false;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة العملاء'),
        trailing: canManage
            ? ActionButton(
                onPressed: _showAddCustomerDialog,
                label: 'إضافة',
                leading: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: !canManage
            ? Center(child: Text(l.permissionDeniedTitle))
            : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: CupertinoTextField(
                      controller: _searchController,
                      placeholder: 'البحث عن عميل...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(CupertinoIcons.search),
                      ),
                      suffix: _searchQuery.isNotEmpty
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                              },
                              child: const Icon(CupertinoIcons.clear),
                            )
                          : null,
                    ),
                  ),

                  // Customer count
                  if (!_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'إجمالي العملاء: ${_customers.length}',
                            style: const TextStyle(
                              fontSize: AppTypography.fs12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            Text(
                              'نتائج البحث: ${_filteredCustomers.length}',
                              style: const TextStyle(
                                fontSize: AppTypography.fs12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // Customer list
                  Expanded(
                    child: _loading
                        ? const Center(child: CupertinoActivityIndicator())
                        : _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.person_2,
                                  size: 64,
                                  color: CupertinoColors.systemGrey,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'لا توجد نتائج للبحث'
                                      : 'لا يوجد عملاء مسجلين',
                                  style: const TextStyle(
                                    fontSize: AppTypography.fs16,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                if (_searchQuery.isEmpty && canManage) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  CupertinoButton.filled(
                                    onPressed: _showAddCustomerDialog,
                                    child: const Text('إضافة أول عميل'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredCustomers.length,
                            separatorBuilder: (context, index) => Container(
                              height: 0.5,
                              color: CupertinoColors.separator,
                            ),
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return CupertinoListTile(
                                title: Text(customer.name),
                                subtitle: customer.phoneNumber != null
                                    ? Text(customer.phoneNumber!)
                                    : const Text('لا يوجد رقم هاتف'),
                                trailing: canManage
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () =>
                                                _showEditCustomerDialog(
                                                  customer,
                                                ),
                                            child: const Icon(
                                              CupertinoIcons.pencil,
                                              color: CupertinoColors.systemBlue,
                                            ),
                                          ),
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () =>
                                                _showDeleteCustomerDialog(
                                                  customer,
                                                ),
                                            child: const Icon(
                                              CupertinoIcons.delete,
                                              color: CupertinoColors.systemRed,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          CustomerDetailsScreen(
                                            customer: customer,
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
    );
  }
}
