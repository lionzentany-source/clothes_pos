import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';
import 'package:clothes_pos/presentation/pos/widgets/product_grid_item.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

/// واجهة البحث المتقدم: ألوان (دوائر) + فئات + أحجام مع تحديث فوري AND filter.
class AdvancedProductSearchScreen extends StatefulWidget {
  const AdvancedProductSearchScreen({super.key});

  /// Opens the advanced search as a Cupertino popup sheet (modal) instead of a full page.
  static Future<void> open(BuildContext context) => showCupertinoModalPopup(
    context: context,
    barrierColor: CupertinoColors.systemGrey.withOpacity(0.25),
    builder: (_) => const AdvancedProductSearchScreen(),
  );

  @override
  State<AdvancedProductSearchScreen> createState() =>
      _AdvancedProductSearchScreenState();
}

class _AdvancedProductSearchScreenState
    extends State<AdvancedProductSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _selectedColors = <String>{};
  final _selectedSizes = <String>{};
  final _selectedCategories = <int>{};
  List<String> _allColors = [];
  List<String> _allSizes = [];
  List<dynamic> _allCategories = [];
  List<Map<String, Object?>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = sl<ProductRepository>();
    final colors = await repo.distinctColors(limit: 200);
    final sizes = await repo.distinctSizes(limit: 200);
    final cats = context
        .read<PosCubit>()
        .state
        .categories; // already loaded in POS
    if (!mounted) return;
    setState(() {
      _allColors = colors;
      _allSizes = sizes;
      _allCategories = cats;
      _loading = false;
    });
    _apply();
  }

  void _toggleColor(String v) {
    setState(() => !_selectedColors.add(v) ? _selectedColors.remove(v) : null);
    _apply();
  }

  void _toggleSize(String v) {
    setState(() => !_selectedSizes.add(v) ? _selectedSizes.remove(v) : null);
    _apply();
  }

  void _toggleCategory(int id) {
    setState(
      () =>
          !_selectedCategories.add(id) ? _selectedCategories.remove(id) : null,
    );
    _apply();
  }

  void _reset() {
    setState(() {
      _selectedColors.clear();
      _selectedSizes.clear();
      _selectedCategories.clear();
      _searchCtrl.clear();
    });
    _apply();
  }

  Future<void> _apply() async {
    final name = _searchCtrl.text.trim();
    final rows = await sl<ProductRepository>().searchVariantRowMaps(
      name: name.isEmpty ? null : name,
      limit: 250,
    );
    final filtered = rows.where((r) {
      bool ok = true;
      if (_selectedColors.isNotEmpty) {
        final c = (r['color'] as String?)?.toLowerCase() ?? '';
        ok &= _selectedColors.any((sel) => c.contains(sel.toLowerCase()));
      }
      if (_selectedSizes.isNotEmpty) {
        final s = (r['size'] as String?)?.toLowerCase() ?? '';
        ok &= _selectedSizes.any((sel) => s == sel.toLowerCase());
      }
      if (_selectedCategories.isNotEmpty) {
        final catId = r['category_id'] as int?; // from DAO alias
        if (catId == null) return false; // row lacks category
        ok &= _selectedCategories.contains(catId);
      }
      return ok;
    }).toList();
    if (!mounted) return;
    setState(() => _results = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.9; // Sheet height cap
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            minHeight: size.height * 0.55,
          ),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                color: Color(0x33000000),
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Grab handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Header row (title + actions)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.searchPlaceholder,
                        style: AppTypography.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minSize: 28,
                      onPressed: _reset,
                      child: const Text('مسح', style: TextStyle(fontSize: 13)),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minSize: 28,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                child: CupertinoSearchTextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _apply(),
                ),
              ),
              const SizedBox(height: 4),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CupertinoActivityIndicator(),
                )
              else
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      _sectionHeader('الألوان'),
                      _colorSection(),
                      _sectionHeader('الفئات'),
                      _categorySection(),
                      _sectionHeader('الأحجام'),
                      _sizeSection(),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.sm,
                        ),
                        sliver: _results.isEmpty
                            ? SliverToBoxAdapter(
                                child: EmptyState(
                                  title: l.notFound,
                                  icon: CupertinoIcons.search,
                                ),
                              )
                            : SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => ProductGridItem(
                                    variant: _results[i],
                                    square: true,
                                    onTap: () {
                                      context.read<PosCubit>().addToCart(
                                        _results[i]['id'] as int,
                                        (_results[i]['sale_price'] as num)
                                            .toDouble(),
                                      );
                                    },
                                  ),
                                  childCount: _results.length,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: AppSpacing.xs,
                                      crossAxisSpacing: AppSpacing.xs,
                                      childAspectRatio: 1,
                                    ),
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xxs,
      ),
      child: Text(title, style: AppTypography.bodyStrong),
    ),
  );

  SliverToBoxAdapter _colorSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final c in _allColors.take(80))
            _ColorCircle(
              name: c,
              selected: _selectedColors.contains(c),
              onTap: () => _toggleColor(c),
            ),
        ],
      ),
    ),
  );

  SliverToBoxAdapter _categorySection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final cat in _allCategories.take(120))
            _SelectableChip(
              label: cat.name.toString(),
              selected: _selectedCategories.contains(cat.id as int),
              onTap: () => _toggleCategory(cat.id as int),
            ),
        ],
      ),
    ),
  );

  SliverToBoxAdapter _sizeSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in _allSizes.take(160))
            _SelectableChip(
              label: s,
              selected: _selectedSizes.contains(s),
              onTap: () => _toggleSize(s),
            ),
        ],
      ),
    ),
  );
}

class _ColorCircle extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _ColorCircle({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  Color _parse(String v) {
    const map = {
      'red': 0xFFE53935,
      'blue': 0xFF1E88E5,
      'green': 0xFF43A047,
      'yellow': 0xFFFBC02D,
      'orange': 0xFFFB8C00,
      'purple': 0xFF8E24AA,
      'pink': 0xFFD81B60,
      'black': 0xFF000000,
      'white': 0xFFFFFFFF,
      'brown': 0xFF6D4C41,
      'grey': 0xFF757575,
      'gray': 0xFF757575,
    };
    final lower = v.toLowerCase().trim();
    if (map.containsKey(lower)) return Color(map[lower]!);
    final hex = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(lower);
    if (hex != null) return Color(int.parse('0xFF${hex.group(1)}'));
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final base = _parse(name);
    final border = selected
        ? CupertinoColors.activeBlue
        : const Color(0x33000000);
    final fg = base.computeLuminance() > 0.6
        ? const Color(0xFF222222)
        : CupertinoColors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: base,
          border: Border.all(color: border, width: 3),
        ),
        alignment: Alignment.center,
        child: selected
            ? Icon(CupertinoIcons.check_mark_circled_solid, size: 18, color: fg)
            : Text(
                name.length <= 3 ? name.toUpperCase() : '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? c.primaryHover : c.border),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? CupertinoColors.white : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
