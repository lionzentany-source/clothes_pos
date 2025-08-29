import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';

import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

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
    final l = AppLocalizations.of(context);
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('دور جديد'),
        content: CupertinoTextField(controller: ctrl, placeholder: 'اسم الدور'),
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
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                await _load();
              } catch (e) {
                if (!mounted || !ctx.mounted) return;
                final friendly = SqlErrorHelper.toArabicMessage(e);
                await showCupertinoDialog(
                  context: ctx,
                  builder: (_) => CupertinoAlertDialog(
                    title: Text(AppLocalizations.of(ctx).error),
                    content: Text(friendly),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(ctx).ok),
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

  Future<void> _editRolePermissions(Map<String, Object?> role) async {
    final roleId = role['id'] as int;
    final current = await _repo.getRolePermissionIds(roleId);
    final selected = current.toSet();
    if (!mounted || !context.mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => CupertinoAlertDialog(
          title: Text('صلاحيات: ${role['name']}'),
          content: SizedBox(
            height: 260,
            width: 320,
            child: ListView(
              children: _permissions.map((p) {
                final pid = p['id'] as int;
                final code = p['code'] as String;
                final desc = (p['description'] as String?)?.trim();
                final display = (desc == null || desc.isEmpty) ? code : desc;
                final on = selected.contains(pid);
                return _CupertinoRowTile(
                  title: Text(display, textDirection: TextDirection.rtl),
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
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel),
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
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameRole(Map<String, Object?> role) async {
    final ctrl = TextEditingController(text: role['name'] as String? ?? '');
    final l = AppLocalizations.of(context);
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('تعديل الاسم'),
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
              try {
                await _repo.renameRole(role['id'] as int, name);
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                await _load();
              } catch (e) {
                if (!mounted || !ctx.mounted) return;
                final friendly = SqlErrorHelper.toArabicMessage(e);
                await showCupertinoDialog(
                  context: ctx,
                  builder: (_) => CupertinoAlertDialog(
                    title: Text(AppLocalizations.of(ctx).error),
                    content: Text(friendly),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(ctx).ok),
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

  Future<void> _deleteRole(Map<String, Object?> role) async {
    final l = AppLocalizations.of(context);
    if (!mounted || !context.mounted) return;
    if (!mounted || !context.mounted) return;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.delete),
        content: Text('حذف الدور "${role['name']}"؟'),
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
          content: const Text('تعذر حذف الدور قد يكون مستخدماً'),
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
    final canManage =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.manageUsers,
        ) ??
        false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('الأدوار و الصلاحيات'),
        trailing: canManage
            ? ActionButton(
                onPressed: _addRoleDialog,
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
            ? Center(
                child: Text(AppLocalizations.of(context).permissionDeniedTitle),
              )
            : _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView.builder(
                itemCount: _roles.length,
                itemBuilder: (ctx, i) {
                  final r = _roles[i];
                  return _CupertinoRowTile(
                    title: Text(r['name'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: canManage
                              ? () => _editRolePermissions(r)
                              : null,
                          child: const Text('الصلاحيات'),
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

class _CupertinoRowTile extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  const _CupertinoRowTile({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: title),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
