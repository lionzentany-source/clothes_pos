import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageAttributesScreen extends StatelessWidget {
  final bool isModal;
  const ManageAttributesScreen({super.key, this.isModal = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context).manageAttributesTitle),
        leading: isModal
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.clear_circled_solid),
              )
            : null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddAttributeDialog(context),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<AttributesCubit, AttributesState>(
          builder: (context, state) {
            if (state is AttributesLoading) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (state is AttributesLoaded) {
              if (state.attributes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.tag,
                        size: 64,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد خصائص بعد',
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على زر + لإضافة خاصية جديدة',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: () => _showAddAttributeDialog(context),
                        child: const Text('إضافة خاصية جديدة'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.attributes.length,
                itemBuilder: (context, index) {
                  final attribute = state.attributes[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header row (attribute name + actions)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  label:
                                      '${AppLocalizations.of(context).attributeNoun}: ${attribute.name}',
                                  child: Text(attribute.name),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _showEditAttributeDialog(
                                      context,
                                      attribute,
                                    ),
                                    child: const Icon(CupertinoIcons.pencil),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _confirmDeleteAttribute(
                                      context,
                                      attribute,
                                    ),
                                    child: const Icon(CupertinoIcons.delete),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        _showAddAttributeValueDialog(
                                          context,
                                          attribute.id!,
                                        ),
                                    child: const Icon(CupertinoIcons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Values list (always visible under header)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: FutureBuilder<List<AttributeValue>>(
                            future: context
                                .read<AttributesCubit>()
                                .attributeRepository
                                .getAttributeValues(attribute.id!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CupertinoActivityIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Text(
                                  '${AppLocalizations.of(context).error}: ${snapshot.error}',
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).noValuesYet,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                );
                              } else {
                                return Column(
                                  children: snapshot.data!.map((value) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Semantics(
                                              label:
                                                  '${AppLocalizations.of(context).valueNoun}: ${value.value}',
                                              child: Text(value.value),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () =>
                                                    _showEditAttributeValueDialog(
                                                      context,
                                                      value,
                                                    ),
                                                child: const Icon(
                                                  CupertinoIcons.pencil,
                                                ),
                                              ),
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () =>
                                                    _confirmDeleteAttributeValue(
                                                      context,
                                                      value,
                                                    ),
                                                child: const Icon(
                                                  CupertinoIcons.delete,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (state is AttributesError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context).error}: ${state.message}',
                ),
              );
            }
            return Center(
              child: Text(AppLocalizations.of(context).noAttributesLoaded),
            );
          },
        ),
      ),
    );
  }

  void _showAddAttributeDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    // Capture parent dependencies to avoid ProviderNotFound inside dialog subtree
    final parentCubit = context.read<AttributesCubit>();
    final parentRepo = parentCubit.attributeRepository;
    final parentLoc = AppLocalizations.of(context);
  if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(parentLoc.addNewAttribute),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              ),
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: parentLoc.attributeNamePlaceholder,
                  ),
                ),
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: Text(parentLoc.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(parentLoc.addAction),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  if (!dialogContext.mounted) return; // safety
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.nameRequired),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                // Use captured dependencies from parent context
                final existing = await parentRepo.getAllAttributes();
                if (existing.any(
                  (a) => a.name.toLowerCase() == name.toLowerCase(),
                )) {
                  if (!dialogContext.mounted) return;
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.attributeExists),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await parentCubit.addAttribute(Attribute(name: name));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                // Show success confirmation for tests
                if (!context.mounted) return;
                await showCupertinoDialog(
                  context: context,
                  builder: (ctx2) => CupertinoAlertDialog(
                    content: const Text('Success'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx2).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditAttributeDialog(BuildContext context, Attribute attribute) {
    final TextEditingController controller = TextEditingController(
      text: attribute.name,
    );
    final parentCubit = context.read<AttributesCubit>();
    final parentRepo = parentCubit.attributeRepository;
    final parentLoc = AppLocalizations.of(context);
  if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(parentLoc.editAttribute),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              ),
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: parentLoc.attributeNamePlaceholder,
                  ),
                ),
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: Text(parentLoc.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(parentLoc.save),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  if (!dialogContext.mounted) return; // safety
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.nameRequired),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                // Use captured from parent
                final existing = await parentRepo.getAllAttributes();
                if (existing.any(
                  (a) =>
                      a.name.toLowerCase() == name.toLowerCase() &&
                      a.id != attribute.id,
                )) {
                  if (!dialogContext.mounted) return;
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.attributeExists),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await parentCubit.updateAttribute(
                  attribute.copyWith(name: name),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                await showCupertinoDialog(
                  context: context,
                  builder: (ctx2) => CupertinoAlertDialog(
                    content: const Text('Success'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx2).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddAttributeValueDialog(BuildContext context, int attributeId) {
    final TextEditingController controller = TextEditingController();
    final parentCubit = context.read<AttributesCubit>();
    final parentLoc = AppLocalizations.of(context);
  if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(parentLoc.addNewValue),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              ),
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: parentLoc.valuePlaceholder,
                  ),
                ),
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: Text(parentLoc.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(parentLoc.addAction),
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) {
                  if (!dialogContext.mounted) return; // safety
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.valueRequired),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await parentCubit.addAttributeValue(
                  AttributeValue(attributeId: attributeId, value: val),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                await showCupertinoDialog(
                  context: context,
                  builder: (ctx2) => CupertinoAlertDialog(
                    content: const Text('Success'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx2).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditAttributeValueDialog(
    BuildContext context,
    AttributeValue value,
  ) {
    final TextEditingController controller = TextEditingController(
      text: value.value,
    );
    final parentCubit = context.read<AttributesCubit>();
    final parentLoc = AppLocalizations.of(context);
  if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(parentLoc.editValue),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              ),
              child: SizedBox(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: parentLoc.valuePlaceholder,
                  ),
                ),
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: Text(parentLoc.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(parentLoc.save),
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) {
                  if (!dialogContext.mounted) return; // safety
                  await showCupertinoDialog(
                    context: dialogContext,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(parentLoc.error),
                      content: Text(parentLoc.valueRequired),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(parentLoc.ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await parentCubit.updateAttributeValue(
                  value.copyWith(value: val),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                await showCupertinoDialog(
                  context: context,
                  builder: (ctx2) => CupertinoAlertDialog(
                    content: const Text('Success'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx2).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAttribute(
    BuildContext context,
    Attribute attribute,
  ) async {
    final c = context; // capture
    final confirm = await showCupertinoDialog<bool>(
      context: c,
      builder: (dctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(dctx).confirmDelete),
        content: Text(
          AppLocalizations.of(dctx).deleteAttributePrompt(attribute.name),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(AppLocalizations.of(dctx).cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dctx).pop(true),
            isDestructiveAction: true,
            child: Text(AppLocalizations.of(dctx).delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!c.mounted) return;
      final cubit = c.read<AttributesCubit>();
      await cubit.deleteAttribute(attribute.id!);
      if (!c.mounted) return;
      await showCupertinoDialog(
        context: c,
        builder: (sctx) => CupertinoAlertDialog(
          content: Text(AppLocalizations.of(sctx).attributeDeleted),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(sctx).pop(),
              child: Text(AppLocalizations.of(sctx).ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmDeleteAttributeValue(
    BuildContext context,
    AttributeValue value,
  ) async {
    final c = context; // capture
    final confirm = await showCupertinoDialog<bool>(
      context: c,
      builder: (dctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(dctx).confirmDelete),
        content: Text(AppLocalizations.of(dctx).deleteValuePrompt(value.value)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(AppLocalizations.of(dctx).cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dctx).pop(true),
            isDestructiveAction: true,
            child: Text(AppLocalizations.of(dctx).delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!c.mounted) return;
      final cubit = c.read<AttributesCubit>();
      await cubit.deleteAttributeValue(value.id!);
      if (!c.mounted) return;
      await showCupertinoDialog(
        context: c,
        builder: (sctx) => CupertinoAlertDialog(
          content: Text(AppLocalizations.of(sctx).valueDeleted),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(sctx).pop(),
              child: Text(AppLocalizations.of(sctx).ok),
            ),
          ],
        ),
      );
    }
  }
}
