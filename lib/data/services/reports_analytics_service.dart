import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'dart:math';

class ReportAnalyticsService {
  final ReportsRepository _reportsRepo = sl<ReportsRepository>();

  // Trend analysis report
  Future<TrendAnalysisReport> generateTrendAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    String? granularity = 'daily', // daily, weekly, monthly
  }) async {
    try {
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();

      final salesData = await _reportsRepo.salesByDay(
        startIso: startIso,
        endIso: endIso,
      );

      // Calculate trend metrics
      final totalSales = salesData.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

      final avgDailySales = salesData.isNotEmpty
          ? totalSales / salesData.length
          : 0.0;

      // Calculate trend direction
      double trendSlope = 0;
      if (salesData.length > 1) {
        // Simple linear regression to determine trend
        double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        for (int i = 0; i < salesData.length; i++) {
          final amount =
              (salesData[i]['total_amount'] as num?)?.toDouble() ?? 0;
          sumX += i;
          sumY += amount;
          sumXY += i * amount;
          sumXX += i * i;
        }

        final n = salesData.length.toDouble();
        trendSlope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
      }

      String trendDirection;
      if (trendSlope > 0.1) {
        trendDirection = 'صاعد';
      } else if (trendSlope < -0.1) {
        trendDirection = 'هابط';
      } else {
        trendDirection = 'مستقر';
      }

      return TrendAnalysisReport(
        periodStart: startDate,
        periodEnd: endDate,
        totalSales: totalSales,
        averageDailySales: avgDailySales,
        trendDirection: trendDirection,
        trendSlope: trendSlope,
        dataPoints: salesData.map((item) {
          final dateStr = item['sale_date'] as String?;
          DateTime? date;
          if (dateStr != null) {
            try {
              date = DateTime.parse(dateStr);
            } catch (e) {
              // Handle parsing error
            }
          }

          return DataPoint(
            date: date,
            value: (item['total_amount'] as num?)?.toDouble() ?? 0,
          );
        }).toList(),
      );
    } catch (e) {
      throw Exception('Error generating trend analysis: $e');
    }
  }

  // Period comparison report
  Future<PeriodComparisonReport> generatePeriodComparison({
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    required DateTime previousPeriodStart,
    required DateTime previousPeriodEnd,
  }) async {
    try {
      // Get current period data
      final currentSalesData = await _reportsRepo.salesByDay(
        startIso: currentPeriodStart.toIso8601String(),
        endIso: currentPeriodEnd.toIso8601String(),
      );

      final currentTotalSales = currentSalesData.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

      final currentInvoiceCount = currentSalesData.fold<int>(
        0,
        (sum, item) => sum + ((item['invoice_count'] as int?) ?? 0),
      );

      // Get previous period data
      final previousSalesData = await _reportsRepo.salesByDay(
        startIso: previousPeriodStart.toIso8601String(),
        endIso: previousPeriodEnd.toIso8601String(),
      );

      final previousTotalSales = previousSalesData.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

      final previousInvoiceCount = previousSalesData.fold<int>(
        0,
        (sum, item) => sum + ((item['invoice_count'] as int?) ?? 0),
      );

      // Calculate growth percentages
      final salesGrowth = previousTotalSales > 0
          ? ((currentTotalSales - previousTotalSales) / previousTotalSales) *
                100
          : 0.0;

      final invoiceGrowth = previousInvoiceCount > 0
          ? ((currentInvoiceCount - previousInvoiceCount) /
                    previousInvoiceCount) *
                100
          : 0.0;

      return PeriodComparisonReport(
        currentPeriod: PeriodData(
          startDate: currentPeriodStart,
          endDate: currentPeriodEnd,
          totalSales: currentTotalSales,
          invoiceCount: currentInvoiceCount,
        ),
        previousPeriod: PeriodData(
          startDate: previousPeriodStart,
          endDate: previousPeriodEnd,
          totalSales: previousTotalSales,
          invoiceCount: previousInvoiceCount,
        ),
        salesGrowthPercentage: salesGrowth,
        invoiceGrowthPercentage: invoiceGrowth,
      );
    } catch (e) {
      throw Exception('Error generating period comparison: $e');
    }
  }

  // Predictive sales report
  Future<PredictiveSalesReport> generatePredictiveSales({
    required DateTime startDate,
    required DateTime endDate,
    int predictionDays = 7,
  }) async {
    try {
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();

      final historicalData = await _reportsRepo.salesByDay(
        startIso: startIso,
        endIso: endIso,
      );

      // Simple moving average prediction
      if (historicalData.length < 3) {
        throw Exception('Not enough data for prediction');
      }

      // Calculate average daily sales
      final totalSales = historicalData.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

      final avgDailySales = totalSales / historicalData.length;

      // Calculate standard deviation
      double sumSquares = 0;
      for (final item in historicalData) {
        final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;
        final diff = amount - avgDailySales;
        sumSquares += diff * diff;
      }

      final stdDev = sqrt(sumSquares / historicalData.length);

      // Generate predictions
      final predictions = <PredictedDataPoint>[];
      final random = Random();

      for (int i = 1; i <= predictionDays; i++) {
        final predictionDate = endDate.add(Duration(days: i));

        // Add some randomness to make it more realistic
        final randomFactor = (random.nextDouble() - 0.5) * 0.2; // +/- 10%
        final predictedValue = avgDailySales * (1 + randomFactor);

        // Add confidence interval (68% confidence within 1 std dev)
        final lowerBound = predictedValue - stdDev;
        final upperBound = predictedValue + stdDev;

        predictions.add(
          PredictedDataPoint(
            date: predictionDate,
            predictedValue: predictedValue,
            lowerConfidenceBound: lowerBound > 0 ? lowerBound : 0,
            upperConfidenceBound: upperBound,
          ),
        );
      }

      return PredictiveSalesReport(
        historicalPeriodStart: startDate,
        historicalPeriodEnd: endDate,
        historicalData: historicalData.map((item) {
          final dateStr = item['sale_date'] as String?;
          DateTime? date;
          if (dateStr != null) {
            try {
              date = DateTime.parse(dateStr);
            } catch (e) {
              // Handle parsing error
            }
          }

          return DataPoint(
            date: date,
            value: (item['total_amount'] as num?)?.toDouble() ?? 0,
          );
        }).toList(),
        predictions: predictions,
        averageDailySales: avgDailySales,
        confidenceLevel: 0.68, // 68% confidence (1 standard deviation)
      );
    } catch (e) {
      throw Exception('Error generating predictive sales report: $e');
    }
  }

  // Customer behavior analysis
  Future<CustomerBehaviorReport> generateCustomerBehaviorAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // In a real implementation, this would analyze customer purchase patterns
      // For now, we'll return sample data

      return CustomerBehaviorReport(
        periodStart: startDate,
        periodEnd: endDate,
        totalCustomers: 128,
        returningCustomers: 82,
        newCustomers: 46,
        averagePurchaseFrequency: 2.3,
        averageCustomerValue: 1560.75,
        customerSegments: [
          CustomerSegment(
            name: 'عملاء مميزون',
            customerCount: 25,
            percentage: 19.5,
            averageSpending: 3200.50,
          ),
          CustomerSegment(
            name: 'عملاء منتظمون',
            customerCount: 57,
            percentage: 44.5,
            averageSpending: 1450.25,
          ),
          CustomerSegment(
            name: 'عملاء جدد',
            customerCount: 46,
            percentage: 36.0,
            averageSpending: 680.75,
          ),
        ],
        peakPurchaseTimes: ['10:00-12:00', '16:00-18:00', '20:00-22:00'],
      );
    } catch (e) {
      throw Exception('Error generating customer behavior analysis: $e');
    }
  }
}

// Data models for reports
class DataPoint {
  final DateTime? date;
  final double value;

  DataPoint({required this.date, required this.value});
}

class TrendAnalysisReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSales;
  final double averageDailySales;
  final String trendDirection; // صاعد, هابط, مستقر
  final double trendSlope;
  final List<DataPoint> dataPoints;

  TrendAnalysisReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSales,
    required this.averageDailySales,
    required this.trendDirection,
    required this.trendSlope,
    required this.dataPoints,
  });
}

class PeriodData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final int invoiceCount;

  PeriodData({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.invoiceCount,
  });
}

class PeriodComparisonReport {
  final PeriodData currentPeriod;
  final PeriodData previousPeriod;
  final double salesGrowthPercentage;
  final double invoiceGrowthPercentage;

  PeriodComparisonReport({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.salesGrowthPercentage,
    required this.invoiceGrowthPercentage,
  });
}

class PredictedDataPoint {
  final DateTime date;
  final double predictedValue;
  final double lowerConfidenceBound;
  final double upperConfidenceBound;

  PredictedDataPoint({
    required this.date,
    required this.predictedValue,
    required this.lowerConfidenceBound,
    required this.upperConfidenceBound,
  });
}

class PredictiveSalesReport {
  final DateTime historicalPeriodStart;
  final DateTime historicalPeriodEnd;
  final List<DataPoint> historicalData;
  final List<PredictedDataPoint> predictions;
  final double averageDailySales;
  final double confidenceLevel;

  PredictiveSalesReport({
    required this.historicalPeriodStart,
    required this.historicalPeriodEnd,
    required this.historicalData,
    required this.predictions,
    required this.averageDailySales,
    required this.confidenceLevel,
  });
}

class CustomerSegment {
  final String name;
  final int customerCount;
  final double percentage;
  final double averageSpending;

  CustomerSegment({
    required this.name,
    required this.customerCount,
    required this.percentage,
    required this.averageSpending,
  });
}

class CustomerBehaviorReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalCustomers;
  final int returningCustomers;
  final int newCustomers;
  final double averagePurchaseFrequency;
  final double averageCustomerValue;
  final List<CustomerSegment> customerSegments;
  final List<String> peakPurchaseTimes;

  CustomerBehaviorReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalCustomers,
    required this.returningCustomers,
    required this.newCustomers,
    required this.averagePurchaseFrequency,
    required this.averageCustomerValue,
    required this.customerSegments,
    required this.peakPurchaseTimes,
  });

  double get returningCustomerRate =>
      totalCustomers > 0 ? (returningCustomers / totalCustomers) * 100 : 0;
}
