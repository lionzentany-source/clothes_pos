import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';

class CategorySidebar extends StatelessWidget {
  final double width;
  const CategorySidebar({
    super.key,
    this.width = 180,
  }); // width constant not tokenized yet

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: BlocBuilder<PosCubit, PosState>(
        builder: (context, state) {
          if (state.categories.isEmpty) {
            return const EmptyState(
              title: 'لا توجد فئات',
              message: 'لم يتم تحميل أي فئات بعد.',
              icon: CupertinoIcons.square_grid_2x2,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  l.categories,
                  style: AppTypography.bodyStrong,
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xxs),
                  itemBuilder: (ctx, i) {
                    final c = state.categories[i];
                    final selected = state.selectedCategoryId == c.id;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: AppSpacing.sm,
                      ),
                      color: selected ? colors.primary : colors.surface,
                      onPressed: () => context.read<PosCubit>().selectCategory(
                        selected ? null : c.id as int,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyStrong.copyWith(
                            color: selected
                                ? CupertinoColors.white
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
