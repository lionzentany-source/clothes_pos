class ChecklistItem {
  final String id;
  final String title;
  final String description;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.isDone = false,
  });
}

final List<ChecklistItem> checklistItems = [
  ChecklistItem(
    id: 'add_product',
    title: 'إضافة أول منتج',
    description: 'أضف منتجًا واحدًا على الأقل إلى مخزونك لتبدأ البيع.',
  ),
  ChecklistItem(
    id: 'make_sale',
    title: 'إجراء أول عملية بيع',
    description: 'قم ببيع منتج من خلال واجهة نقاط البيع.',
  ),
  ChecklistItem(
    id: 'open_cash_session',
    title: 'فتح أول جلسة صندوق',
    description: 'افتح جلسة صندوق جديدة لتسجيل المبيعات النقدية.',
  ),
  ChecklistItem(
    id: 'add_expense',
    title: 'إضافة أول مصروف',
    description: 'سجل أول مصروف لك لتتبع نفقاتك.',
  ),
];
