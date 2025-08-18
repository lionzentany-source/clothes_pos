import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';

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
    final users = await _repo.listAllUsers();
    final roles = await _repo.listRoles();
    if (!mounted) return;
    setState(() {
      _users = users;
      _roles = roles;
      _loading = false;
    });
  }

  Future<void> _showAddUserDialog() async {
    final l = AppLocalizations.of(context)!;
    final usernameCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final selectedRoles = <int>{};

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          return CupertinoAlertDialog(
            title: Text(l.addAction),
            content: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoTextField(
                  placeholder: l.userNamePlaceholder,
                  controller: usernameCtrl,
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  placeholder: l.fullNamePlaceholder,
                  controller: fullNameCtrl,
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  placeholder: l.loginEnterPassword,
                  controller: passwordCtrl,
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.rolesLabel),
                ),
                SizedBox(
                  height: 120,
                  child: CupertinoScrollbar(
                    child: ListView(
                      children: _roles.map((r) {
                        final id = r['id'] as int;
                        final name = r['name'] as String;
                        final selected = selectedRoles.contains(id);
                        return CupertinoListTile(
                          title: Text(name),
                          trailing: CupertinoSwitch(
                            value: selected,
                            onChanged: (v) => setInner(() {
                              if (v) {
                                selectedRoles.add(id);
                              } else {
                                selectedRoles.remove(id);
                              }
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.cancel),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  final u = usernameCtrl.text.trim();
                  final p = passwordCtrl.text.trim();
                  if (u.isEmpty || p.length < 4) return;
                  await _repo.createUser(
                    username: u,
                    fullName: fullNameCtrl.text.trim().isEmpty
                        ? null
                        : fullNameCtrl.text.trim(),
                    password: p,
                    roleIds: selectedRoles.toList(),
                  );
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  setState(() => _loading = true);
                  await _load();
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changePassword(int userId) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.changePassword),
        content: CupertinoTextField(
          placeholder: l.loginEnterPassword,
          controller: ctrl,
          obscureText: true,
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
              await _repo.changePassword(userId, p);
              if (!mounted) return;
              Navigator.of(ctx).pop();
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
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context)!.rolesLabel),
          content: SizedBox(
            height: 200,
            child: CupertinoScrollbar(
              child: ListView(
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
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                await _repo.setUserRoles(userId, selected.toList());
                if (!mounted) return;
                Navigator.of(ctx).pop();
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(AppUser u) async {
    final l = AppLocalizations.of(context)!;
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
    final l = AppLocalizations.of(context)!;
    final perms =
        context.watch<AuthCubit>().state.user?.permissions ?? const [];
    final canManage = perms.contains(AppPermissions.manageUsers);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.usersManagementTitle),
      ),
      child: SafeArea(
        child: !canManage
            ? Center(child: Text(l.permissionDeniedTitle))
            : _loading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CupertinoButton.filled(
                          onPressed: _showAddUserDialog,
                          child: Text(l.addAction),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          onPressed: _load,
                          child: Text(l.update),
                        ),
                      ],
                    ),
                  ),
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
                          subtitle: Text(u.isActive ? l.active : l.inactive),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                onPressed: () => _editRoles(u.id),
                                child: Text(l.rolesLabel),
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
