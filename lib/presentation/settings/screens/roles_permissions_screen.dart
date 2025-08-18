import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';

class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({super.key});
  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> {
  final _repo = sl<UsersRepository>();
  bool _loading = true;
  List<Map<String, Object?>> _roles = const [];
  List<Map<String, Object?>> _permissions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roles = await _repo.listRoles();
    final perms = await _repo.listPermissions();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _permissions = perms;
      _loading = false;
    });
    final auth = context.read<AuthCubit>().state.user;
    if (auth != null &&
        !auth.permissions.contains(AppPermissions.manageUsers)) {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _addRoleDialog() async {
    final ctrl = TextEditingController();
    final l = AppLocalizations.of(context)!;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.newRoleTitle),
        content: CupertinoTextField(
          controller: ctrl,
          placeholder: l.roleNamePlaceholder,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                await _repo.createRole(name);
                if (!mounted) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                await _load();
              } catch (e) {
                // يمكن إظهار رسالة خطأ لاحقاً
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Future<void> _editRolePermissions(Map<String, Object?> role) async {
    final l = AppLocalizations.of(context)!;
    final roleId = role['id'] as int;
    final current = await _repo.getRolePermissionIds(roleId);
    final selected = current.toSet();
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => CupertinoAlertDialog(
          title: Text('${l.permissionsTitle}: ${role['name'] as String? ?? ''}'),
          content: SizedBox(
            height: 260,
            width: 320,
            child: CupertinoScrollbar(
              child: ListView(
                children: _permissions.map((p) {
                  final pid = p['id'] as int;
                  final code = p['code'] as String;
                  final on = selected.contains(pid);
                  return CupertinoListTile(
                    title: Text(code),
                    trailing: CupertinoSwitch(
                      value: on,
                      onChanged: (v) => setInner(() {
                        if (v) {
                          selected.add(pid);
                        } else {
                          selected.remove(pid);
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                await _repo.setRolePermissions(roleId, selected.toList());
                if (mounted) {
                  await context
                      .read<AuthCubit>()
                      .refreshCurrentUserPermissions();
                }
                if (!mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameRole(Map<String, Object?> role) async {
    final ctrl = TextEditingController(text: role['name'] as String? ?? '');
    final l = AppLocalizations.of(context)!;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.editNameTitle),
        content: CupertinoTextField(controller: ctrl),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await _repo.renameRole(role['id'] as int, name);
              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() => _loading = true);
              await _load();
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRole(Map<String, Object?> role) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.delete),
        content: Text(l.deleteRoleConfirm(role['name'] as String? ?? '')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _repo.deleteRole(role['id'] as int);
    if (!mounted) return;
    if (success) {
      setState(() => _loading = true);
      await _load();
      if (mounted) {
        await context.read<AuthCubit>().refreshCurrentUserPermissions();
      }
    } else {
      await showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l.error),
          content: Text(l.deleteRoleFailed),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.ok),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canManage =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.manageUsers,
        ) ??
        false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.rolesPermissionsTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: canManage ? _addRoleDialog : null,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: !canManage
            ? Center(
                child: Text(
                  AppLocalizations.of(context)!.permissionDeniedTitle,
                ),
              )
            : _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView.builder(
                itemCount: _roles.length,
                itemBuilder: (ctx, i) {
                  final r = _roles[i];
                  return CupertinoListTile(
                    title: Text(r['name'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: canManage
                              ? () => _editRolePermissions(r)
                              : null,
                          child: Text(l.permissionsLabel),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: canManage ? () => _renameRole(r) : null,
                          child: const Icon(CupertinoIcons.pencil, size: 18),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: canManage ? () => _deleteRole(r) : null,
                          child: const Icon(
                            CupertinoIcons.delete,
                            size: 18,
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
