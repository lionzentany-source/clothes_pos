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
  final List<AttributeValue> _selected = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      _selected.addAll(widget.initialSelected!);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final attrs = await widget.loadAttributes();
    _attributes = attrs;
    for (final a in attrs) {
      final vals = await widget.loadAttributeValues(a.id!);
      _values[a.id!] = vals;
    }
    setState(() => _loading = false);
  }

  List<AttributeValue> _searchResults() {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    final out = <AttributeValue>[];
    for (final vs in _values.values) {
      for (final v in vs) {
        if (v.value.toLowerCase().contains(q)) out.add(v);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 6),
            CupertinoSearchTextField(
              onChanged: (s) => setState(() => _query = s),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _query.trim().isNotEmpty
                  ? _buildSearchList()
                  : _buildGroupedList(),
            ),
            const SizedBox(height: 12),
            // Suggestions: when searching show suggested tags (not already selected)
            if (_query.trim().isNotEmpty) _buildSuggestions(),
            const SizedBox(height: 8),
            // Selected items: pure-Cupertino draggable reorder using
            // LongPressDraggable + DragTarget. This removes any Material
            // dependency while preserving the previous fallback keys used in tests.
            SizedBox(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _selected.length; i++)
                      DragTarget<int>(
                        onWillAcceptWithDetails: (details) => details.data != i,
                        onAcceptWithDetails: (details) {
                          final from = details.data;
                          if (from == i) return;
                          setState(() {
                            final item = _selected.removeAt(from);
                            var insertIndex = i;
                            if (from < insertIndex) insertIndex -= 1;
                            if (insertIndex < 0) insertIndex = 0;
                            if (insertIndex > _selected.length) {
                              insertIndex = _selected.length;
                            }
                            _selected.insert(insertIndex, item);
                          });
                        },
                        builder: (context, candidate, rejected) {
                          final v = _selected[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Left chevron with semantics
                                Semantics(
                                  key: ValueKey('sel-left-${v.id}'),
                                  button: true,
                                  label: 'Move ${v.value} left',
                                  child: GestureDetector(
                                    onTap: i > 0
                                        ? () => setState(() {
                                            final it = _selected.removeAt(i);
                                            _selected.insert(i - 1, it);
                                          })
                                        : null,
                                    child: Icon(
                                      CupertinoIcons.chevron_left,
                                      size: 18,
                                      color: i > 0
                                          ? null
                                          : CupertinoColors.inactiveGray,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                LongPressDraggable<int>(
                                  data: i,
                                  axis: Axis.horizontal,
                                  feedback: Transform.scale(
                                    scale: 1.06,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey4,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: CupertinoColors.systemGrey
                                                .withOpacity(0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        v.value,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _buildSelectedChip(v),
                                  ),
                                  child: Semantics(
                                    container: true,
                                    label: 'Selected ${v.value}',
                                    child: _buildSelectedChip(
                                      v,
                                      key: ValueKey('sel-fallback-${v.id}'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Right chevron with semantics
                                Semantics(
                                  key: ValueKey('sel-right-${v.id}'),
                                  button: true,
                                  label: 'Move ${v.value} right',
                                  child: GestureDetector(
                                    onTap: i < _selected.length - 1
                                        ? () => setState(() {
                                            final it = _selected.removeAt(i);
                                            _selected.insert(i + 1, it);
                                          })
                                        : null,
                                    child: Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 18,
                                      color: i < _selected.length - 1
                                          ? null
                                          : CupertinoColors.inactiveGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    // End drop target to allow dropping after the last item
                    DragTarget<int>(
                      onWillAcceptWithDetails: (details) =>
                          details.data != _selected.length - 1,
                      onAcceptWithDetails: (details) {
                        final from = details.data;
                        setState(() {
                          final item = _selected.removeAt(from);
                          _selected.add(item);
                        });
                      },
                      builder: (c, a, r) => const SizedBox(width: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              child: const Text('تم'),
              onPressed: () => widget.onDone(_selected.toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchList() {
    final results = _searchResults();
    if (results.isEmpty) return const Center(child: Text('No matches'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, idx) {
        final v = results[idx];
        final selected = _selected.any((e) => e.id == v.id);
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
    // Show a horizontal list of suggestions (values not yet selected)
    final suggestions = results
        .where((r) => !_selected.any((s) => s.id == r.id))
        .toList();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) {
          final v = suggestions[i];
          return GestureDetector(
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

  Widget _buildSelectedChip(AttributeValue v, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey4,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v.value),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.clear_circled_solid, size: 16),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    return ListView.builder(
      itemCount: _attributes.length,
      itemBuilder: (context, idx) {
        final attr = _attributes[idx];
        final vals = _values[attr.id!] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                attr.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              children: vals.map((v) {
                final selected = _selected.contains(v);
                return GestureDetector(
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
}