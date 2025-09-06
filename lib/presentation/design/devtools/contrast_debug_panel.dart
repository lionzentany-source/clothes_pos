import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

/// Simple dev-only panel to list contrast ratios of key semantic role pairs.
/// Use only in debug builds (wrap with assert). Not included in production UI.
class ContrastDebugPanel extends StatelessWidget {
  const ContrastDebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = context.colors;
    final rows = <_PairTest>[
      _PairTest('Primary on Surface', roles.primary, roles.surface),
      _PairTest('TextPrimary on Surface', roles.textPrimary, roles.surface),
      _PairTest(
        'TextSecondary on Surface',
        roles.textSecondary,
        roles.surface,
        min: 3.0,
      ),
      _PairTest('Danger on Surface', roles.danger, roles.surface),
      _PairTest('Success on Surface', roles.success, roles.surface),
    ];
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Contrast Debug'),
      ),
      child: SafeArea(
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (ctx, i) {
            final r = rows[i];
            final ratio = ContrastChecker.contrastRatio(r.fg, r.bg);
            final pass = ratio >= r.min;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: roles.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: roles.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ratio: ${ratio.toStringAsFixed(2)} (min ${r.min})',
                          style: TextStyle(
                            color: pass ? roles.textSecondary : roles.danger,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 28,
                    decoration: BoxDecoration(
                      color: r.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: roles.border),
                    ),
                    alignment: Alignment.center,
                    child: Text('Aa', style: TextStyle(color: r.fg)),
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

class _PairTest {
  final String label;
  final Color fg;
  final Color bg;
  final double min;
  _PairTest(this.label, this.fg, this.bg, {this.min = 4.5});
}
