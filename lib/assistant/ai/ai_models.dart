import 'dart:convert';
import 'package:flutter/foundation.dart';

// --- Enums and Extensions ---

// Represents the status of an AI request lifecycle.
enum AiRequestStatus { pending, processing, completed, failed, cancelled }

// Expanded metric types to include more advanced analytics.
enum MetricType {
  // Basic metrics
  sales,
  returns,
  expenses,
  profit,
  inventory,
  customers,
  // Advanced analytics
  topProducts,
  lowStock,
  deadStock, // New: For identifying non-selling products
  customerSegmentation, // New: For analyzing customer groups
}

extension MetricTypeExtension on MetricType {
  static MetricType? fromString(String value) {
    final normalized = value.toLowerCase().trim().replaceAll(' ', '_');
    for (final type in MetricType.values) {
      if (type.name == normalized) {
        return type;
      }
    }
    // Add Arabic mappings for convenience
    switch (normalized) {
      case 'مبيعات':
        return MetricType.sales;
      case 'مرتجعات':
        return MetricType.returns;
      case 'مصروفات':
        return MetricType.expenses;
      case 'أرباح':
        return MetricType.profit;
      case 'مخزون':
        return MetricType.inventory;
      case 'عملاء':
        return MetricType.customers;
      case 'أفضل_منتجات':
        return MetricType.topProducts;
      case 'مخزون_منخفض':
        return MetricType.lowStock;
      case 'مخزون_راكد':
        return MetricType.deadStock;
      case 'تحليل_العملاء':
        return MetricType.customerSegmentation;
      default:
        return null;
    }
  }

  String get stringValue => name;

  String get displayNameAr {
    switch (this) {
      case MetricType.sales:
        return 'المبيعات';
      case MetricType.returns:
        return 'المرتجعات';
      case MetricType.expenses:
        return 'المصروفات';
      case MetricType.profit:
        return 'الأرباح';
      case MetricType.inventory:
        return 'المخزون';
      case MetricType.customers:
        return 'العملاء';
      case MetricType.topProducts:
        return 'أفضل المنتجات';
      case MetricType.lowStock:
        return 'المخزون المنخفض';
      case MetricType.deadStock:
        return 'المخزون الراكد';
      case MetricType.customerSegmentation:
        return 'تحليل العملاء';
    }
  }
}

// --- Core Data Models ---

class AiSettings {
  final bool enabled;
  final Uri? baseUrl;
  final String model;
  final String? apiKey;
  final double temperature;
  final Duration requestTimeout;
  final int maxRetries;

  AiSettings({
    required this.enabled,
    required this.baseUrl,
    required this.model,
    this.apiKey,
    required this.temperature,
    this.requestTimeout = const Duration(
      seconds: 45,
    ), // Increased timeout for complex tasks
    this.maxRetries = 3,
  });

  bool get isValid =>
      enabled &&
      baseUrl != null &&
      model.isNotEmpty &&
      (apiKey?.isNotEmpty ?? false) &&
      temperature >= 0 &&
      temperature <= 2;
}

class AiResult {
  final AiAction action;
  final String? rawModelText;

  AiResult({required this.action, this.rawModelText});
}

// --- AI Actions (Expanded) ---

abstract class AiAction {
  const AiAction();
  String get actionType;
  Map<String, dynamic> toJson();
}

// Basic Actions
class OpenScreenAction extends AiAction {
  final String tab;
  final String? screen; // Added to support specific sub-screens
  const OpenScreenAction({required this.tab, this.screen});
  @override
  String get actionType => 'open_screen';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'tab': tab,
    if (screen != null) 'screen': screen,
  };
}

class AnswerFaqAction extends AiAction {
  final String text;
  const AnswerFaqAction(this.text);
  @override
  String get actionType => 'answer_faq';
  @override
  Map<String, dynamic> toJson() => {'action': actionType, 'text': text};
}

class UnknownAction extends AiAction {
  final String? originalText;
  const UnknownAction({this.originalText});
  @override
  String get actionType => 'unknown';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'original_text': originalText,
  };
}

// Data Query Actions
class QueryMetricAction extends AiAction {
  final MetricType metric;
  final String range;
  final Map<String, dynamic>? filters;
  const QueryMetricAction({
    required this.metric,
    required this.range,
    this.filters,
  });
  @override
  String get actionType => 'query_metric';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'metric': metric.stringValue,
    'range': range,
    if (filters != null) 'filters': filters,
  };
}

class SearchProductAction extends AiAction {
  final String query;
  const SearchProductAction({required this.query});
  @override
  String get actionType => 'search_product';
  @override
  Map<String, dynamic> toJson() => {'action': actionType, 'query': query};
}

// --- Actions added to fix errors ---

class CreateReportAction extends AiAction {
  final String type;
  final String range;
  const CreateReportAction({required this.type, required this.range});
  @override
  String get actionType => 'create_report';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'type': type,
    'range': range,
  };
}

class SearchCustomerAction extends AiAction {
  final String query;
  const SearchCustomerAction({required this.query});
  @override
  String get actionType => 'search_customer';
  @override
  Map<String, dynamic> toJson() => {'action': actionType, 'query': query};
}

class QueryInventoryAction extends AiAction {
  final String query;
  final String? status; // Added status field
  const QueryInventoryAction({required this.query, this.status});
  @override
  String get actionType => 'query_inventory';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'query': query,
    if (status != null) 'status': status,
  };
}

class AddProductAction extends AiAction {
  final String name;
  final double salePrice;
  final int quantity;
  final String? size;
  final String? color;
  final String? category;

  const AddProductAction({
    required this.name,
    required this.salePrice,
    required this.quantity,
    this.size,
    this.color,
    this.category,
  });

  @override
  String get actionType => 'add_product';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'name': name,
    'sale_price': salePrice,
    'quantity': quantity,
    'size': size,
    'color': color,
    'category': category,
  };
}

// --- User-suggested Actions ---

/// Action to forecast demand for a specific product.
class ForecastDemandAction extends AiAction {
  final String productName;
  final String period; // e.g., "next_week", "next_month"
  const ForecastDemandAction({required this.productName, required this.period});
  @override
  String get actionType => 'forecast_demand';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'product_name': productName,
    'period': period,
  };
}

/// Action to analyze the root cause of a business anomaly.
class AnalyzeRootCauseAction extends AiAction {
  final String eventDescription; // e.g., "low sales on Tuesday"
  final String date;
  const AnalyzeRootCauseAction({
    required this.eventDescription,
    required this.date,
  });
  @override
  String get actionType => 'analyze_root_cause';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'event': eventDescription,
    'date': date,
  };
}

/// Action to automatically generate a description for a product.
class GenerateProductDescriptionAction extends AiAction {
  final String productName;
  final List<String> keywords; // e.g., ["cotton", "blue", "slim_fit"]
  const GenerateProductDescriptionAction({
    required this.productName,
    required this.keywords,
  });
  @override
  String get actionType => 'generate_product_description';
  @override
  Map<String, dynamic> toJson() => {
    'action': actionType,
    'product_name': productName,
    'keywords': keywords,
  };
}

// --- Action Parser (Expanded) ---

class ActionParser {
  static AiAction parseConstrainedAction(String text) {
    try {
      final cleanText = text
          .trim()
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      if (cleanText.isEmpty) {
        return const UnknownAction(originalText: 'Empty response from model');
      }

      final Map<String, dynamic> json = jsonDecode(cleanText);
      final action = json['action']?.toString().toLowerCase() ?? '';

      switch (action) {
        case 'open_screen':
          return OpenScreenAction(
            tab: json['tab'] ?? '',
            screen: json['screen'] as String?,
          );
        case 'answer_faq':
          return AnswerFaqAction(json['text'] ?? '');
        case 'query_metric':
          final metric = MetricTypeExtension.fromString(json['metric'] ?? '');
          if (metric != null) {
            return QueryMetricAction(
              metric: metric,
              range: json['range'] ?? 'today',
              filters: json['filters'] as Map<String, dynamic>?,
            );
          }
          break;
        case 'search_product':
          return SearchProductAction(query: json['query'] ?? '');
        case 'create_report':
          return CreateReportAction(
            type: json['type'] ?? '',
            range: json['range'] ?? '',
          );
        case 'search_customer':
          return SearchCustomerAction(query: json['query'] ?? '');
        case 'query_inventory':
          return QueryInventoryAction(
            query: json['query'] ?? '',
            status: json['status'] as String?,
          );
        case 'add_product':
          return AddProductAction(
            name: json['name'] ?? '',
            salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
            quantity: (json['quantity'] as num?)?.toInt() ?? 0,
            size: json['size'] as String?,
            color: json['color'] as String?,
            category: json['category'] as String?,
          );
        case 'forecast_demand':
          return ForecastDemandAction(
            productName: json['product_name'] ?? '',
            period: json['period'] ?? '',
          );
        case 'analyze_root_cause':
          return AnalyzeRootCauseAction(
            eventDescription: json['event'] ?? '',
            date: json['date'] ?? '',
          );
        case 'generate_product_description':
          final keywords = (json['keywords'] as List?)?.cast<String>() ?? [];
          return GenerateProductDescriptionAction(
            productName: json['product_name'] ?? '',
            keywords: keywords,
          );
      }
      return UnknownAction(originalText: text);
    } catch (e) {
      debugPrint('Error parsing action JSON: $e');
      if (text.length < 200) {
        return AnswerFaqAction(text);
      }
      return UnknownAction(originalText: text);
    }
  }
}

// --- Custom Exceptions ---

class AiException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AiException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AiException: $message${code != null ? ' ($code)' : ''}';
}

class AiConnectionException extends AiException {
  const AiConnectionException(super.message, {super.code, super.originalError});
}

class AiRateLimitException extends AiException {
  final Duration retryAfter;
  const AiRateLimitException(
    super.message,
    this.retryAfter, {
    super.code,
    super.originalError,
  });
}
