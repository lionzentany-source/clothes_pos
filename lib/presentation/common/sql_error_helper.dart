class SqlErrorHelper {
  static String toArabicMessage(Object error) {
    final msg = error.toString();
    final low = msg.toLowerCase();
    // SQLite common patterns
    if (low.contains('unique')) {
      if (low.contains('sku')) {
        return 'رقم الصنف (SKU) مستخدم مسبقاً، يرجى اختيار رقم مختلف.';
      }
      if (low.contains('username')) {
        return 'اسم المستخدم مستخدم مسبقاً.';
      }
      if (low.contains('phone')) {
        return 'رقم الهاتف مستخدم مسبقاً.';
      }
      if (low.contains('suppliers') || low.contains('supplier')) {
        return 'اسم المورد موجود مسبقاً.';
      }
      if (low.contains('categories') || low.contains('category')) {
        return 'اسم الفئة موجود مسبقاً.';
      }
      if (low.contains('brands') || low.contains('brand')) {
        return 'اسم العلامة التجارية موجود مسبقاً.';
      }
      if (low.contains('barcode')) {
        return 'الباركود مستخدم مسبقاً.';
      }
      // Generic
      return 'هناك قيمة مكررة تخالف شرط التفرد.';
    }
    if (low.contains('foreign key')) {
      return 'لا يمكن تنفيذ العملية بسبب ارتباطات في البيانات.';
    }
    if (low.contains('not null')) {
      return 'هناك حقل مطلوب بدون قيمة. يرجى التحقق من المدخلات.';
    }
    if (low.contains('constraint') && low.contains('failed')) {
      return 'فشل التحقق من القيود. يرجى التحقق من المدخلات.';
    }
    if (low.contains('no such table') || low.contains('no such column')) {
      return 'قاعدة البيانات غير مهيأة بشكل صحيح. يرجى التأكد من الترقية أو إعادة الاستعادة.';
    }
    if (low.contains('database is locked')) {
      return 'قاعدة البيانات مشغولة حالياً. الرجاء المحاولة بعد لحظات.';
    }
    return 'حدث خطأ أثناء حفظ البيانات. الرجاء المحاولة مرة أخرى.';
  }
}
