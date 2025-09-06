import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:flutter/cupertino.dart' hide CupertinoListTile;
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/widgets/cupertino_list_tile_stub.dart';

import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});
  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final _repo = sl<UsersRepository>();
  bool _loading = true;
  List<AppUser> _users = const [];
  List<Map<String, Object?>> _roles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    String? errorMsg;
    try {
      // تحديد حد أقصى للبيانات
      final users = await _repo.listAllUsers(limit: 100);
      final roles = await _repo.listRoles(limit: 50);
      if (!mounted) return;
      setState(() {
        _users = users;
        _roles = roles;
        _loading = false;
      });
    } catch (e) {
      errorMsg = SqlErrorHelper.toArabicMessage(e);
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      if (!context.mounted) return; // safety
      await showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context).error),
          content: Text(errorMsg ?? 'حدث خطأ غير متوقع أثناء تحميل البيانات'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _changePassword(int userId) async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    if (!context.mounted) return; // safety
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.changePassword),
        content: CupertinoTextField(
          placeholder: l.loginEnterPassword,
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: CupertinoColors.label),
          placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
          obscuringCharacter: '•',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final p = ctrl.text.trim();
              if (p.length < 4) return;
              try {
                await _repo.changePassword(userId, p);
                if (!mounted || !ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                final friendly = SqlErrorHelper.toArabicMessage(e);
                await showCupertinoDialog(
                  context: ctx,
                  builder: (_) => CupertinoAlertDialog(
                    title: Text(AppLocalizations.of(context).error),
                    content: Text(friendly),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppLocalizations.of(context).ok),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Future<void> _editRoles(int userId) async {
    final current = await _repo.getUserRoleIds(userId);
    final selected = current.toSet();
    if (!mounted || !context.mounted) return;
    if (!context.mounted) return; // safety
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final rolesScrollCtrl = ScrollController();
          return CupertinoAlertDialog(
            title: const Text('الأدوار'),
            content: SizedBox(
              height: 200,
              child: CupertinoScrollbar(
                controller: rolesScrollCtrl,
                child: ListView(
                  controller: rolesScrollCtrl,
                  children: _roles.map((r) {
                    final id = r['id'] as int;
                    final name = r['name'] as String;
                    final on = selected.contains(id);
                    return CupertinoListTile(
                      title: Text(name),
                      trailing: CupertinoSwitch(
                        value: on,
                        onChanged: (v) => setInner(() {
                          if (v) {
                            selected.add(id);
                          } else {
                            selected.remove(id);
                          }
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  try {
                    await _repo.setUserRoles(userId, selected.toList());
                    if (!mounted || !ctx.mounted) return;
                    Navigator.of(ctx).pop();
                  } catch (e) {
                    final friendly = SqlErrorHelper.toArabicMessage(e);
                    await showCupertinoDialog(
                      context: ctx,
                      builder: (_) => CupertinoAlertDialog(
                        title: Text(AppLocalizations.of(ctx).error),
                        content: Text(friendly),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(AppLocalizations.of(ctx).ok),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context).save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteUser(AppUser u) async {
    final l = AppLocalizations.of(context);
    if (!context.mounted) return; // safety
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.delete),
        content: Text('Delete ${u.username}?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.deleteUserHard(u.id);
    if (!mounted) return;
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final perms =
        context.watch<AuthCubit>().state.user?.permissions ?? const [];
    final canManage = perms.contains(AppPermissions.manageUsers);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إدارة المستخدمين'),
      ),
      child: SafeArea(
        child: !canManage
            ? Center(child: Text(l.permissionDeniedTitle))
            : _loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(height: 16),
                  Text('جاري تحميل المستخدمين والصلاحيات...'),
                ],
              )
            : Column(
                children: [
                  Container(height: 0.5, color: CupertinoColors.separator),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final u = _users[i];
                        return CupertinoListTile(
                          title: Text(
                            u.fullName?.isNotEmpty == true
                                ? '${u.fullName} (${u.username})'
                                : u.username,
                          ),
                          subtitle: Text(u.isActive ? 'نشط' : 'غير نشط'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                onPressed: () => _editRoles(u.id),
                                child: const Text('الأدوار'),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                onPressed: () => _changePassword(u.id),
                                child: Text(l.changePassword),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                onPressed: () => _deleteUser(u),
                                child: Text(l.delete),
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
