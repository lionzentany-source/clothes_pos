import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';

/// Small reusable widget to render variant attribute values in a compact form.
class VariantAttributesDisplay extends StatelessWidget {
  // Accept dynamic lists so callers can pass model lists, maps, or simple strings.
  final List<dynamic>? attributes;
  const VariantAttributesDisplay({super.key, required this.attributes});

  String _toValue(dynamic a) {
    if (a == null) return '';
    if (a is String) return a;
    // Map-based attribute (from DB row)
    if (a is Map) return (a['value'] ?? '').toString();
    // Try dynamic access for model objects with `value` field
    try {
      final dyn = a as dynamic;
      final val = dyn.value;
      if (val == null) return a.toString();
      return val.toString();
    } catch (_) {
      return a.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.useDynamicAttributes) return const SizedBox.shrink();
    if (attributes == null || attributes!.isEmpty) {
      return const SizedBox.shrink();
    }
    final values = attributes!
        .map(_toValue)
        .where((s) => s.isNotEmpty)
        .toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final text = values.join(' • ');
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyStrong.copyWith(
        color: CupertinoTheme.of(context).textTheme.textStyle.color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
