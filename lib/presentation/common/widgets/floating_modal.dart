import 'package:flutter/cupertino.dart';

enum ModalSize {
  small, // للتأكيدات البسيطة
  medium, // للنماذج العادية
  large, // للشاشات المعقدة
  fullWidth, // لعرض النص الطويل
}

/// Widget مساعد لإنشاء نوافذ عائمة في وسط الشاشة
class FloatingModal extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double widthFactor;
  final double heightFactor;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final String? title;
  final bool showCloseButton;
  final ModalSize? modalSize;
  final bool scrollable;

  FloatingModal({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.widthFactor = 0.8,
    this.heightFactor = 0.8,
    this.margin = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.title,
    this.showCloseButton = true,
    this.modalSize,
    this.scrollable = true,
  }) : assert(() {
         // Defensive: when scrollable is true, we will wrap `child` with
         // SingleChildScrollView. If `child` is a Column that contains
         // Flexible/Expanded, this will cause an unbounded height error.
         if (scrollable && child is Column) {
           final Column col = child;
           final hasFlexChild = col.children.any(
             (w) => w is Flexible || w is Expanded,
           );
           if (hasFlexChild) {
             throw FlutterError(
               'FloatingModal(scrollable: true) cannot wrap a Column that contains Flexible/Expanded.\n'
               'This creates unbounded height constraints when placed inside a SingleChildScrollView and will throw at runtime.\n\n'
               'Fixes:\n'
               '• Set scrollable: false on FloatingModal and make only an inner content area scrollable.\n'
               '• Or refactor the child so that Flexible/Expanded are not inside a scrollable parent.\n\n'
               'Tip: When using a header, keep the header outside the scroll, and wrap only the content with Flexible + ListView/CustomScrollView.',
             );
           }
         }
         return true;
       }());

  /// عرض النافذة العائمة مع حجم محدد مسبقاً
  static Future<T?> showWithSize<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    ModalSize size = ModalSize.medium,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    bool scrollable = true,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => FloatingModal(
        title: title,
        showCloseButton: showCloseButton,
        modalSize: size,
        scrollable: scrollable,
        child: child,
      ),
    );
  }

  /// عرض النافذة العائمة مع أبعاد مخصصة
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    double widthFactor = 0.8,
    double heightFactor = 0.8,
    EdgeInsets margin = const EdgeInsets.all(20),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    bool barrierDismissible = true,
    bool scrollable = true,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => FloatingModal(
        width: width,
        height: height,
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        margin: margin,
        borderRadius: borderRadius,
        scrollable: scrollable,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    double effectiveWidth;
    double effectiveHeight;

    // إذا كان modalSize محدد، استخدم القيم المحددة مسبقاً
    if (modalSize != null) {
      switch (modalSize!) {
        case ModalSize.small:
          effectiveWidth = (screenSize.width * 0.35).clamp(280.0, 450.0);
          effectiveHeight = (screenSize.height * 0.6).clamp(300.0, 500.0);
          break;
        case ModalSize.medium:
          effectiveWidth = (screenSize.width * 0.5).clamp(400.0, 650.0);
          effectiveHeight = (screenSize.height * 0.75).clamp(400.0, 600.0);
          break;
        case ModalSize.large:
          effectiveWidth = (screenSize.width * 0.7).clamp(600.0, 900.0);
          effectiveHeight = (screenSize.height * 0.85).clamp(500.0, 800.0);
          break;
        case ModalSize.fullWidth:
          effectiveWidth = (screenSize.width * 0.9).clamp(700.0, 1000.0);
          effectiveHeight = (screenSize.height * 0.8).clamp(400.0, 700.0);
          break;
      }
    } else {
      // استخدم القيم المخصصة
      effectiveWidth = width ?? screenSize.width * widthFactor;
      effectiveHeight = height ?? screenSize.height * heightFactor;
    }

    // When we have a header, we must NOT wrap the entire column with
    // SingleChildScrollView because it contains a Flexible which requires
    // bounded height. Instead, make only the content area scrollable.
    final bool hasHeader = (title != null || showCloseButton);
    Widget content;
    if (hasHeader) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGrey6,
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showCloseButton)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.systemGrey,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          // Content - bounded by Flexible; wrap only the inner child if scrollable
          Flexible(
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ],
      );
    } else {
      // No header => we can wrap the provided child directly
      content = scrollable ? SingleChildScrollView(child: child) : child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveWidth,
          maxHeight: effectiveHeight == double.infinity
              ? screenSize.height * 0.9
              : effectiveHeight,
          minWidth: modalSize == ModalSize.small ? 280 : 400,
          minHeight: 200,
        ),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            // 'content' is already wrapped appropriately depending on header
            child: content,
          ),
        ),
      ),
    );
  }
}
