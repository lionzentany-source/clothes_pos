import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/customer_repository.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class CustomerSelectionModal extends StatefulWidget {
  final Customer? currentCustomer;
  final Function(Customer?) onCustomerSelected;

  const CustomerSelectionModal({
    super.key,
    this.currentCustomer,
    required this.onCustomerSelected,
  });

  static Future<void> show({
    required BuildContext context,
    Customer? currentCustomer,
    required Function(Customer?) onCustomerSelected,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CustomerSelectionModal(
        currentCustomer: currentCustomer,
        onCustomerSelected: onCustomerSelected,
      ),
    );
  }

  @override
  State<CustomerSelectionModal> createState() => _CustomerSelectionModalState();
}

class _CustomerSelectionModalState extends State<CustomerSelectionModal> {
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
      final customers = await _customerRepo.listAll(limit: 500);
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
      }
    }
  }

  Future<void> _showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showCupertinoDialog<Customer?>(
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
            onPressed: () => Navigator.of(context).pop(),
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
                final id = await _customerRepo.create(customer, userId: userId);
                final newCustomer = customer.copyWith(id: id);

                if (context.mounted) {
                  Navigator.of(context).pop(newCustomer);
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

    if (result != null) {
      await _loadCustomers();
      widget.onCustomerSelected(result);
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('اختيار العميل'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddCustomerDialog,
          child: const Text('إضافة'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Clear customer option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupertinoButton.filled(
                onPressed: () {
                  widget.onCustomerSelected(null);
                  Navigator.of(context).pop();
                },
                child: const Text('بيع بدون عميل'),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

            const SizedBox(height: AppSpacing.sm),

            // Customer count
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'العملاء: ${_customers.length}',
                      style: const TextStyle(
                        fontSize: AppTypography.fs12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                      Text(
                        'النتائج: ${_filteredCustomers.length}',
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
                          if (_searchQuery.isEmpty) ...[
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
                        final isSelected =
                            widget.currentCustomer?.id == customer.id;

                        return CupertinoListTile(
                          title: Text(customer.name),
                          subtitle: customer.phoneNumber != null
                              ? Text(customer.phoneNumber!)
                              : const Text('لا يوجد رقم هاتف'),
                          trailing: isSelected
                              ? const Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: CupertinoColors.activeGreen,
                                )
                              : null,
                          onTap: () {
                            widget.onCustomerSelected(customer);
                            Navigator.of(context).pop();
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
