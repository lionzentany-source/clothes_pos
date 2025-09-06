# UI Redesign Roadmap (POS)

Status legend: [ ] pending, [~] in-progress, [x] done, [>] deferred

## Phase 1 – Design System Foundations

- [x] Create tokens: colors.dart
- [x] Create tokens: spacing.dart
- [x] Create tokens: typography.dart
- [x] Create tokens: radii.dart
- [x] Create tokens: shadows.dart
- [x] Create component tokens: app_buttons.dart (primary / secondary / ghost / icon)
- [x] Central theme wrapper app_theme.dart
- [x] Replace magic spacing (4,8,12,16,24,32) with constants (اكتمل في مكونات POS الحالية)
- [x] Replace font sizes (12,14,16,18,22) with constants (أضيفت fs10 و fs11 وأزيلت القيم الخام)
- [x] Introduce semantic color roles (primary, primaryVariant, surface, background, border, danger, success, warning)

## Phase 2 – Layout Refactor

- [x] CategorySidebar widget (vertical list w/ selection state)
- [x] ProductGridItem widget (name+price + placeholder thumbnail + stock badge)
- [~] CartPanel widget (list + summary footer; تبقى تحسين أنيميشن وتبسيط عناصر التحكم بالكمية)
- [x] Integrate new widgets into PosScreen (replaced legacy inline layout; further polish pending)
- [x] Responsive breakpoints (<=900 narrow stacked; >900 ثلاثة أعمدة) (أُنجزت المرحلة الأولى؛ تحسينات أنيميشن لاحقاً)

## Phase 3 – Interaction Enhancements

- [x] Debounced search (300ms) service (implemented in PosCubit.debouncedSearch + wired to search fields)
- [x] Highlight matched query substring in results (first occurrence bolded in list/grid names)
- [x] FilterChipsBar (size/color/brand) replacing ActionSheets (integrated narrow + wide; sheets removed)
- [x] QuantityControl compact capsule (+/-) (component created and integrated in CartPanel)

## Phase 4 – Payment & Feedback Revamp

- [x] Full-screen PaymentModal ( multi-method inputs + quick amounts)
- [x] Unified Toast/Overlay system (success, error, info)
- [x] Empty states (categories, results, cart) with illustrative icon & guidance
- [x] Inline validation for payment inputs (negative value checks in PaymentModal)
- [x] Change/remaining dynamic color indicators (warning/success/accent in PaymentModal)

## Phase 5 – Visual & Performance Polish

- [x] Product thumbnails placeholder (SVG)
- [x] Shimmer placeholder while loading products (grid/list skeletons)
- [x] Implicit animations for cart add/remove & quantity changes (Size/Fade/Slide + note transitions)
- [x] WCAG AA contrast audit & adjustments (accessible secondary text colors + audit tool)
- [x] Optimize rebuilds (consts, variant name cache, AnimatedSwitcher diffs, minimal rebuild footprint)

## Quick Wins (Parallel)

- [x] Show product name in cart instead of ID only (تمت عبر resolver مؤقت + كاش، تحسين الأداء لاحقاً)
- [x] FooterBar with total items | amount | primary checkout button
- [x] Replace +/- row with QuantityControl component

## Benchmarks (Target)

- Add to cart < 120ms
- Open payment modal < 200ms
- 90% primary actions <= 2 clicks
- Payment input error rate < 2%

---

Implementation order follows phases; quick wins can merge early if low-risk.

## Change Log

(append entries as tasks complete)

- 2025-08-16: CategorySidebar implemented and integrated into PosScreen (wide layout breakpoint at 1100px).
- 2025-08-16: ProductGridItem (initial version) created & integrated for search results and quick items (no thumbnail/stock badge yet).
- 2025-08-16: ProductGridItem enhanced with placeholder thumbnail + stock badge.
- 2025-08-16: CartPanel initial extraction & integration; later enhanced with sticky summary footer (still using placeholder item names).
- 2025-08-16: Rebuilt corrupted PosScreen, modularized structure (CategorySidebar, ProductGridItem, CartPanel) and restored compilation.
- 2025-08-16: استبدال الفراغات (spacing) السحرية في كامل مكونات POS بـ AppSpacing.
- 2025-08-16: عرض اسم المنتج في السلة بدل الـ ID (باستخدام resolveVariantName + كاش مبدئي).
- 2025-08-16: بدء تنفيذ الـ Responsive: إضافة وضع ضيق (<=900px) مع لوحة سلة سفلية قابلة للطي وزر فئات.
- 2025-08-16: تحسين الـ Responsive: دمج quick items في الوضع الضيق + Sheet للمرشحات (حجم/لون) + ارتفاع ديناميكي للوحة السلة.
- 2025-08-16: تحسين أداء اسم المتغير في السلة عبر getVariantDisplayName + كاش بدل البحث الكامل.
- 2025-08-16: إضافة debounced search + دمج في حقول البحث.
- 2025-08-16: تمييز الجزء المطابق للبحث داخل أسماء النتائج (bold match).
- 2025-08-16: استبدال أزرار +/- في السلة بمكون QuantityControl.
