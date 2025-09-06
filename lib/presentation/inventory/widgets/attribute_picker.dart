import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/models/attribute.dart';

typedef LoadAttributes = Future<List<Attribute>> Function();
typedef LoadAttributeValues =
    Future<List<AttributeValue>> Function(int attributeId);

class AttributePicker extends StatefulWidget {
  final LoadAttributes loadAttributes;
  final LoadAttributeValues loadAttributeValues;
  final List<AttributeValue>? initialSelected;
  final void Function(List<AttributeValue>) onDone;

  const AttributePicker({
    super.key,
    required this.loadAttributes,
    required this.loadAttributeValues,
    this.initialSelected,
    required this.onDone,
  });

  @override
  State<AttributePicker> createState() => _AttributePickerState();
}

class _AttributePickerState extends State<AttributePicker> {
  List<Attribute> _attributes = [];
  final Map<int, List<AttributeValue>> _values = {};
  final Map<int, bool> _loadingAttr = {};
  final Map<int, String> _normalizedCache = {};
  final List<AttributeValue> _selected = [];
  bool _loading = true;
  bool _prefetchedForSearch = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      _selected.addAll(widget.initialSelected!);
    }
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    setState(() => _loading = true);
    try {
      _attributes = await widget.loadAttributes();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _normalize(String input) {
    final lower = input.toLowerCase();
    final stripped = lower.replaceAll(
      RegExp('[\u064B-\u065F\u0670\u0671\u06D6-\u06ED\u0640]'),
      '',
    );
    return stripped
        .replaceAll(RegExp('[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(' +'), ' ')
        .trim();
  }

  Future<void> _ensureValues(int attributeId) async {
    if (_values.containsKey(attributeId) || _loadingAttr[attributeId] == true) {
      return;
    }
    _loadingAttr[attributeId] = true;
    try {
      final raw = await widget.loadAttributeValues(attributeId);
      final dedup = <String, AttributeValue>{};
      for (final v in raw) {
        final key = _normalize(v.value);
        dedup.putIfAbsent(key, () => v);
      }
      final list = dedup.values.toList();
      for (final v in list) {
        if (v.id != null) _normalizedCache[v.id!] = _normalize(v.value);
      }
      _values[attributeId] = list;
    } catch (e) {
      debugPrint('[AttributePicker] load values error: $e');
      _values[attributeId] = const <AttributeValue>[];
    } finally {
      _loadingAttr[attributeId] = false;
      if (mounted) setState(() {});
    }
  }

  List<AttributeValue> _searchResults() {
    final q = _query.trim();
    if (q.isEmpty) return [];
    final nq = _normalize(q);
    if (!_prefetchedForSearch) {
      _prefetchedForSearch = true;
      for (final a in _attributes) {
        if (a.id != null) _ensureValues(a.id!);
      }
    }
    final out = <AttributeValue>[];
    for (final entries in _values.values) {
      for (final v in entries) {
        final norm = v.id != null
            ? (_normalizedCache[v.id!] ??= _normalize(v.value))
            : _normalize(v.value);
        if (norm.contains(nq)) out.add(v);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        minHeight: 300,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoSearchTextField(
            key: const ValueKey('attribute_picker.search'),
            placeholder: 'بحث في القيم...',
            onChanged: (s) => setState(() => _query = s),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    key: ValueKey('attribute_picker.loading'),
                    child: CupertinoActivityIndicator(),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_query.trim().isNotEmpty) ...[
                          _buildSearchList(),
                          const SizedBox(height: 12),
                          _buildSuggestions(),
                        ] else ...[
                          _buildGroupedList(),
                        ],
                        if (_selected.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSelectedChipsSection(),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              key: const ValueKey('attribute_picker.done'),
              onPressed: () => widget.onDone(_selected.toList()),
              child: const Text('تم'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchList() {
    final results = _searchResults();
    if (results.isEmpty) return const Center(child: Text('No matches'));
    return ListView.builder(
      key: const ValueKey('attribute_picker.search_results'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final v = results[i];
        final selected = _selected.any((s) => s.id == v.id);
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          key: ValueKey('attribute_picker.search_item_${v.id ?? i}'),
          onPressed: () => setState(() {
            if (selected) {
              _selected.removeWhere((e) => e.id == v.id);
            } else {
              _selected.add(v);
            }
          }),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(v.value),
              if (selected) const Icon(CupertinoIcons.check_mark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    final results = _searchResults();
    if (results.isEmpty) return const SizedBox.shrink();
    final suggestions = results
        .where((r) => !_selected.any((s) => s.id == r.id))
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) {
          final v = suggestions[i];
          return GestureDetector(
            key: ValueKey('attribute_picker.suggestion_${v.id ?? i}'),
            onTap: () => setState(() => _selected.add(v)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(v.value),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedList() {
    return ListView.builder(
      key: const ValueKey('attribute_picker.grouped_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attributes.length,
      itemBuilder: (context, idx) {
        final attr = _attributes[idx];
        if (attr.id != null) _ensureValues(attr.id!);
        final vals = attr.id == null
            ? const <AttributeValue>[]
            : (_values[attr.id!] ?? const <AttributeValue>[]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                attr.name,
                key: ValueKey('attribute_picker.group_${attr.id ?? idx}'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: vals.map((v) {
                final selected = _selected.contains(v);
                return GestureDetector(
                  key: ValueKey('attribute_picker.value_${v.id ?? v.value}'),
                  onTap: () => setState(
                    () => selected ? _selected.remove(v) : _selected.add(v),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      v.value,
                      style: TextStyle(
                        color: selected
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildSelectedChipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'العناصر المختارة:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selected.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final v = _selected[i];
              return Container(
                key: v.id != null ? ValueKey('sel-fallback-${v.id}') : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      key: ValueKey('sel-left-${v.id}') as Key?,
                      onTap: i > 0
                          ? () => setState(() {
                              final tmp = _selected[i - 1];
                              _selected[i - 1] = _selected[i];
                              _selected[i] = tmp;
                            })
                          : null,
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        size: 18,
                        color: i > 0
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.inactiveGray,
                      ),
                    ),
                    const SizedBox(width: 2),
                    _buildSelectedChip(v, key: ValueKey('sel-chip-${v.id}')),
                    const SizedBox(width: 2),
                    GestureDetector(
                      key: ValueKey('sel-right-${v.id}') as Key?,
                      onTap: i < _selected.length - 1
                          ? () => setState(() {
                              final tmp = _selected[i + 1];
                              _selected[i + 1] = _selected[i];
                              _selected[i] = tmp;
                            })
                          : null,
                      child: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 18,
                        color: i < _selected.length - 1
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.inactiveGray,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectedChip(AttributeValue v, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CupertinoColors.systemBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            v.value,
            style: const TextStyle(
              color: CupertinoColors.systemBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () =>
                setState(() => _selected.removeWhere((s) => s.id == v.id)),
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              size: 16,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }
}
