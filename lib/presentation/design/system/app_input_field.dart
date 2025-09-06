import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final void Function(String value)? onChanged;
  const AppInputField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  final _focus = FocusNode();
  bool _hover = false;
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = _focus.hasFocus;
    final borderColor = widget.error != null
        ? c.danger
        : focused
        ? c.primary
        : _hover
        ? c.primaryHover
        : c.border;
    final bg = widget.enabled ? c.surface : c.surfaceAlt;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs - 2,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: focused ? 1.4 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: c.focusRing.withValues(alpha: .35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: CupertinoTextField(
                controller: widget.controller,
                placeholder: widget.placeholder,
                enabled: widget.enabled,
                focusNode: _focus,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: const BoxDecoration(),
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
              ),
            ),
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.error!,
                  style: AppTypography.caption.copyWith(color: c.danger),
                ),
              )
            else if (widget.helper != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.helper!,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
