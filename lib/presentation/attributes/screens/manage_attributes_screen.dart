import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageAttributesScreen extends StatelessWidget {
  const ManageAttributesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context).manageAttributesTitle),
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
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(AppLocalizations.of(dialogContext).addNewAttribute),
          content: CupertinoTextField(
            controller: controller,
            placeholder: AppLocalizations.of(
              dialogContext,
            ).attributeNamePlaceholder,
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Add'),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).nameRequired,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                final repo = context
                    .read<AttributesCubit>()
                    .attributeRepository;
                final existing = await repo.getAllAttributes();
                if (existing.any(
                  (a) => a.name.toLowerCase() == name.toLowerCase(),
                )) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).attributeExists,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await context.read<AttributesCubit>().addAttribute(
                  Attribute(name: name),
                );
                Navigator.of(dialogContext).pop();
                Future.microtask(() async {
                  if (!context.mounted) return;
                  await showCupertinoDialog(
                    context: context,
                    builder: (BuildContext innerContext) =>
                        CupertinoAlertDialog(
                          content: Text(
                            AppLocalizations.of(context).attributeAdded,
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.of(innerContext).pop(),
                              child: Text(AppLocalizations.of(context).ok),
                            ),
                          ],
                        ),
                  );
                });
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
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(AppLocalizations.of(dialogContext).editAttribute),
          content: CupertinoTextField(
            controller: controller,
            placeholder: AppLocalizations.of(
              dialogContext,
            ).attributeNamePlaceholder,
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Save'),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).nameRequired,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                final repo = context
                    .read<AttributesCubit>()
                    .attributeRepository;
                final existing = await repo.getAllAttributes();
                if (existing.any(
                  (a) =>
                      a.name.toLowerCase() == name.toLowerCase() &&
                      a.id != attribute.id,
                )) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).attributeExists,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                await context.read<AttributesCubit>().updateAttribute(
                  attribute.copyWith(name: name),
                );
                Navigator.of(dialogContext).pop();
                Future.microtask(() async {
                  if (!context.mounted) return;
                  await showCupertinoDialog(
                    context: context,
                    builder: (BuildContext innerContext) =>
                        CupertinoAlertDialog(
                          content: Text(
                            AppLocalizations.of(context).attributeSaved,
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.of(innerContext).pop(),
                              child: Text(AppLocalizations.of(context).ok),
                            ),
                          ],
                        ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddAttributeValueDialog(BuildContext context, int attributeId) {
    final TextEditingController controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(AppLocalizations.of(dialogContext).addNewValue),
          content: CupertinoTextField(
            controller: controller,
            placeholder: AppLocalizations.of(dialogContext).valuePlaceholder,
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Add'),
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).valueRequired,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await context.read<AttributesCubit>().addAttributeValue(
                  AttributeValue(attributeId: attributeId, value: val),
                );
                Navigator.of(dialogContext).pop();
                Future.microtask(() async {
                  if (!context.mounted) return;
                  await showCupertinoDialog(
                    context: context,
                    builder: (BuildContext innerContext) =>
                        CupertinoAlertDialog(
                          content: Text(
                            AppLocalizations.of(context).valueAdded,
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.of(innerContext).pop(),
                              child: Text(AppLocalizations.of(context).ok),
                            ),
                          ],
                        ),
                  );
                });
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
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(AppLocalizations.of(dialogContext).editValue),
          content: CupertinoTextField(
            controller: controller,
            placeholder: AppLocalizations.of(dialogContext).valuePlaceholder,
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Save'),
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) {
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: Text(AppLocalizations.of(dialogContext).error),
                      content: Text(
                        AppLocalizations.of(dialogContext).valueRequired,
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(AppLocalizations.of(dialogContext).ok),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                await context.read<AttributesCubit>().updateAttributeValue(
                  value.copyWith(value: val),
                );
                Navigator.of(dialogContext).pop();
                Future.microtask(() async {
                  if (!context.mounted) return;
                  await showCupertinoDialog(
                    context: context,
                    builder: (BuildContext innerContext) =>
                        CupertinoAlertDialog(
                          content: Text(
                            AppLocalizations.of(context).valueSaved,
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.of(innerContext).pop(),
                              child: Text(AppLocalizations.of(context).ok),
                            ),
                          ],
                        ),
                  );
                });
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
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(
          AppLocalizations.of(context).deleteAttributePrompt(attribute.name),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AttributesCubit>().deleteAttribute(attribute.id!);
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          content: Text(AppLocalizations.of(context).attributeDeleted),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).ok),
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
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(
          AppLocalizations.of(context).deleteValuePrompt(value.value),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AttributesCubit>().deleteAttributeValue(value.id!);
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          content: Text(AppLocalizations.of(context).valueDeleted),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      );
    }
  }
}
