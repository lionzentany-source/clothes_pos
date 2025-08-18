import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'db_backup_restore_screen.dart';
import 'store_info_screen.dart' hide AppLocalizations;
import 'language_currency_screen.dart';
import 'change_password_screen.dart';
import 'inventory_settings_screen.dart';
import 'printing_settings_screen.dart';
import 'rfid_settings_screen.dart';
import 'users_management_screen.dart';
import 'roles_permissions_screen.dart';
import 'package:clothes_pos/core/auth/permissions.dart';

class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  final _cashRepo = sl<CashRepository>();

  Future<void> _logout() async {
    final user = context.read<AuthCubit>().state.user;
    // If there is an open session, prompt to close it
    final session = await _cashRepo.getOpenSession();
    if (session != null && user != null) {
      final l = AppLocalizations.of(context)!;
      final closing = await _promptForNumber(
        l.logoutConfirmCloseSessionTitle,
        l.logoutConfirmCloseSessionAmount,
      );
      if (closing == null) return; // cancelled
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
      builder: (ctx) {
        final l = AppLocalizations.of(context)!;
        return CupertinoPopupSurface(
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
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: () {
                            final v = double.tryParse(ctrl.text.trim());
                            if (v == null) {
                              showCupertinoDialog(
                                context: ctx,
                                builder: (_) => CupertinoAlertDialog(
                                  title: Text(l.error),
                                  content: Text(l.enterValidNumber),
                                ),
                              );
                              return;
                            }
                            Navigator.of(ctx).pop(v);
                          },
                          child: Text(l.endSession),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            _SectionTitle(AppLocalizations.of(context)!.generalSection),
            _NavTile(
              title: AppLocalizations.of(context)!.storeInfo,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const StoreInfoScreen()),
              ),
            ),
            _NavTile(
              title: AppLocalizations.of(context)!.languageCurrency,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const LanguageCurrencyScreen(),
                ),
              ),
            ),
            _NavTile(
              title: AppLocalizations.of(context)!.changePassword,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
            ),
            _SectionTitle(AppLocalizations.of(context)!.databaseSection),
            _NavTile(
              title: AppLocalizations.of(context)!.dbBackupRestore,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const DbBackupRestoreScreen(),
                ),
              ),
            ),
            _SectionTitle(
              AppLocalizations.of(context)!.inventoryPrintRfidSection,
            ),
            _NavTile(
              title: AppLocalizations.of(context)!.inventorySettings,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const InventorySettingsScreen(),
                ),
              ),
            ),
            _NavTile(
              title: AppLocalizations.of(context)!.printingSettings,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const PrintingSettingsScreen(),
                ),
              ),
            ),
            _NavTile(
              title: AppLocalizations.of(context)!.rfidSettings,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const RfidSettingsScreen()),
              ),
            ),
            _SectionTitle(AppLocalizations.of(context)!.userAccountSection),
            Builder(
              builder: (ctx) {
                final perms =
                    ctx.watch<AuthCubit>().state.user?.permissions ?? const [];
                final hasManage = perms.contains(AppPermissions.manageUsers);
        final l = AppLocalizations.of(context)!;
        final note = hasManage ? null : l.restrictedNoManage;
                return Column(
                  children: [
                    _NavTile(
          title: l.usersManagementTitle,
                      subtitle: note,
                      enabled: hasManage,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const UsersManagementScreen(),
                        ),
                      ),
                    ),
                    _NavTile(
          title: l.rolesPermissionsTitle,
                      subtitle: note,
                      enabled: hasManage,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const RolesPermissionsScreen(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                final l = AppLocalizations.of(context)!;
                return CupertinoListTile(
                  title: Text(
                    l.logout,
                    style: const TextStyle(
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.arrow_right_square,
                    color: CupertinoColors.destructiveRed,
                  ),
                  onTap: _logout,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  const _NavTile({
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    final baseStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final disabled = CupertinoColors.systemGrey;
    return CupertinoListTile(
      title: Text(
        title,
        style: (enabled
            ? baseStyle.copyWith(
                color: CupertinoColors.label,
                fontWeight: FontWeight.w500,
                fontSize: (baseStyle.fontSize ?? 16) + 1,
              )
            : baseStyle.copyWith(color: disabled)),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: baseStyle.copyWith(
                fontSize: 12,
                color: enabled ? CupertinoColors.secondaryLabel : disabled,
              ),
            ),
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        color: enabled ? CupertinoColors.systemGrey : disabled,
        size: 18,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
