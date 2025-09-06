import '../../assistant/ai/ai_models.dart';

class ActionExecutor {
  Future<String> execute(AiAction action) async {
    if (action is QueryMetricAction) {
      return 'قيمة المقياس المطلوب: ${action.metric.stringValue} (${action.range})';
    } else if (action is AnswerFaqAction) {
      return action.text;
    } else if (action is OpenScreenAction) {
      return 'فتح الشاشة: ${action.tab}${action.screen != null ? ' (${action.screen})' : ''}';
    } else if (action is SearchProductAction) {
      return 'نتيجة البحث عن المنتج: ${action.query}';
    } else if (action is SearchCustomerAction) {
      return 'نتيجة البحث عن العميل: ${action.query}';
    } else if (action is QueryInventoryAction) {
      return 'استعلام حالة المخزون: ${action.query} (الحالة: ${action.status ?? 'غير محددة'})';
    } else if (action is AddProductAction) {
      return 'تمت إضافة المنتج: ${action.name}';
    } else if (action is CreateReportAction) {
      return 'تم إنشاء التقرير: ${action.type} (${action.range})';
    } else {
      return 'لم أفهم طلبك.';
    }
  }
}