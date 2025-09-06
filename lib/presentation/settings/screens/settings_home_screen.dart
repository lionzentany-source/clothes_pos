// Clean replacement implementing wide split: detail on left, nav list on right.
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'db_backup_restore_screen.dart';
import 'store_information_screen.dart';
import 'change_password_screen.dart';
import 'inventory_settings_screen.dart';
import 'printing_settings_screen.dart';
import 'rfid_settings_screen.dart';
import 'shift_screen.dart';
import 'package:clothes_pos/presentation/expenses/screens/expense_list_screen.dart';
import 'users_management_screen.dart';
import 'roles_permissions_screen.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/assistant/ai/ai_settings_screen.dart';
import 'package:clothes_pos/assistant/assistant_screen.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  final _cashRepo = sl<CashRepository>();
  int _selectedNavIndex = 0;
  // Toggle to choose selected-item style: pill (white pill with dark text) or blue-filled (blue with white text)
  bool _usePillSelectedStyle = true;

  Future<void> _logout() async {
    final user = context.read<AuthCubit>().state.user;
    final session = await _cashRepo.getOpenSession();
    if (session != null && user != null) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final closing = await _promptForNumber(
        l.logoutConfirmCloseSessionTitle,
        l.logoutConfirmCloseSessionAmount,
      );
      if (closing == null) return;
      await _cashRepo.closeSession(
        sessionId: session['id'] as int,
        closedBy: user.id,
        closingAmount: closing,
      );
    }
    if (!mounted) return;
    context.read<AuthCubit>().logout();
  }

  Future<double?> _promptForNumber(String title, String placeholder) async {
    final ctrl = TextEditingController();
    return showCupertinoModalPopup<double>(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: ctrl,
                  placeholder: placeholder,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: () {
                          final v = double.tryParse(ctrl.text.trim());
                          if (v == null) return;
                          Navigator.of(ctx).pop(v);
                        },
                        child: Text(AppLocalizations.of(context).endSession),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.settingsTitle)),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;

            // Group settings into logical sections for clearer navigation.
            final navGroups = <Map<String, List<_NavItem>>>[
              // Store + account
              {
                'المتجر': [
                  _NavItem(
                    title: l.storeInfo,
                    builder: (_) => const StoreInformationScreen(),
                  ),
                  _NavItem(
                    title: 'إدارة الجلسة',
                    builder: (_) => const ShiftScreen(),
                  ),
                  _NavItem(
                    title: l.changePassword,
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ],
              },

              // Attributes (feature flag)
              if (FeatureFlags.useDynamicAttributes)
                {
                  'السمات': [
                    _NavItem(
                      title: l.manageAttributesTitle,
                      builder: (_) => BlocProvider<AttributesCubit>(
                        create: (_) => sl<AttributesCubit>()..loadAttributes(),
                        child: const ManageAttributesScreen(),
                      ),
                    ),
                  ],
                },

              // Data & backup + inventory-related
              {
                'البيانات والنسخ': [
                  _NavItem(
                    title: l.dbBackupRestore,
                    builder: (_) => const DbBackupRestoreScreen(),
                  ),
                  _NavItem(
                    title: l.inventorySettings,
                    builder: (_) => const InventorySettingsScreen(),
                  ),
                  _NavItem(
                    title: 'المصروفات',
                    builder: (_) => const ExpenseListScreen(),
                  ),
                ],
              },

              // Printing / hardware
              {
                'الطباعة و الأجهزة': [
                  _NavItem(
                    title: l.printingSettings,
                    builder: (_) => const PrintingSettingsScreen(),
                  ),
                  _NavItem(
                    title: l.rfidSettings,
                    builder: (_) => const RfidSettingsScreen(),
                  ),
                ],
              },

              // Assistant & AI
              {
                'الذكاء والمساعد': [
                  _NavItem(
                    title: 'المساعد التدريبي (بدون إنترنت)',
                    builder: (_) => const AssistantScreen(),
                  ),
                  _NavItem(
                    title: 'إعدادات الذكاء الاصطناعي',
                    builder: (_) => const AiSettingsScreen(),
                  ),
                ],
              },

              // Users & permissions
              {
                'المستخدمون': [
                  _NavItem(
                    title: 'إدارة المستخدمين',
                    builder: (_) => const UsersManagementScreen(),
                  ),
                  _NavItem(
                    title: 'الأدوار و الصلاحيات',
                    builder: (_) => const RolesPermissionsScreen(),
                  ),
                ],
              },

              // Actions
              {
                'أخرى': [
                  _NavItem(
                    title: l.logout,
                    builder: (_) => Center(
                      child: AppPrimaryButton(
                        onPressed: _logout,
                        child: Text(l.logout),
                      ),
                    ),
                  ),
                ],
              },
            ];

            // Flatten for detail rendering index mapping (computed on demand)

            Widget navListBuilder() {
              // read current authenticated user to render account header
              final authUser = context.watch<AuthCubit>().state.user;
              final displayName =
                  (authUser?.fullName != null && authUser!.fullName!.isNotEmpty)
                  ? authUser.fullName!
                  : (authUser?.username ?? '');
              final subtitle = authUser?.username ?? '';
              final parts = displayName.split(RegExp(r'\s+'))
                ..removeWhere((s) => s.isEmpty);
              String initials;
              if (parts.isEmpty) {
                initials = (subtitle.isNotEmpty ? subtitle[0] : '?')
                    .toUpperCase();
              } else if (parts.length == 1) {
                initials = parts.first.substring(0, 1).toUpperCase();
              } else {
                initials = (parts[0][0] + parts[1][0]).toUpperCase();
              }

              // header widget that will be part of the scrollable list
              final header = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: AppTextButton(
                    onPressed: () {}, // tappable but no action
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 20,
                          color: context.colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final styleToggle = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نمط التحديد: ظل ابيض'),
                    CupertinoSwitch(
                      value: _usePillSelectedStyle,
                      onChanged: (v) =>
                          setState(() => _usePillSelectedStyle = v),
                    ),
                  ],
                ),
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        header,
                        styleToggle,
                        // build each section and its items inline so everything scrolls together
                        for (
                          var groupIndex = 0;
                          groupIndex < navGroups.length;
                          groupIndex++
                        )
                          () {
                            final section = navGroups[groupIndex];
                            final sectionTitle = section.keys.first;
                            final items = section.values.first;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    sectionTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                for (var j = 0; j < items.length; j++)
                                  (() {
                                    // compute flat index
                                    var flatIndex = 0;
                                    for (var gi = 0; gi < groupIndex; gi++) {
                                      flatIndex +=
                                          navGroups[gi].values.first.length;
                                    }
                                    flatIndex += j;

                                    final item = items[j];
                                    return Column(
                                      children: [
                                        _NavButton(
                                          title: item.title,
                                          selected:
                                              isWide &&
                                              _selectedNavIndex == flatIndex,
                                          usePill: _usePillSelectedStyle,
                                          onPressed: () {
                                            if (isWide) {
                                              setState(
                                                () => _selectedNavIndex =
                                                    flatIndex,
                                              );
                                            } else {
                                              Navigator.of(context).push(
                                                CupertinoPageRoute(
                                                  builder: (_) =>
                                                      item.builder(context),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    );
                                  })(),
                              ],
                            );
                          }(),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (isWide) {
              // Force LTR layout for the Row so the nav sidebar stays visually on the right
              // even when the app Directionality is RTL (Arabic). This keeps detail on left.
              // Build a flattened list of nav items so index -> builder mapping is always correct
              Widget buildDetail(int index) {
                final flat = navGroups.expand((m) => m.values.first).toList();
                if (index < 0 || index >= flat.length) {
                  return Center(
                    child: Text(
                      'اختر عنصراً من القائمة على اليمين لعرض التفاصيل',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  );
                }
                return flat[index].builder(context);
              }

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

  // detail builders are taken directly from `navGroups` so _buildDetailForIndex is no longer needed
}

class _NavItem {
  final String title;
  final Widget Function(BuildContext) builder;
  _NavItem({required this.title, required this.builder});
}

/// Small animated nav button used in the right-side settings list.
class _NavButton extends StatelessWidget {
  final String title;
  final bool selected;
  final bool usePill;
  final VoidCallback onPressed;

  const _NavButton({
    required this.title,
    required this.selected,
    required this.usePill,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Colors: pill selected -> surface (white) + dark text; otherwise blue filled with white text
    final bgColor = (selected && usePill)
        ? context.colors.surface
        : CupertinoColors.activeBlue;
    final textColor = (selected && usePill)
        ? context.colors.textPrimary
        : CupertinoColors.white;
    final radius = BorderRadius.circular(usePill && selected ? 24 : 10);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(color: bgColor, borderRadius: radius),
        child: AppTextButton(
          onPressed: onPressed,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_forward, size: 18, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
