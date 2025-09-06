import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class ReturnsRepository {
  final ReturnsDao dao;
  ReturnsRepository(this.dao);

  Future<List<Map<String, Object?>>> getReturnableItems(int saleId) =>
      dao.getReturnableItems(saleId);
  Future<int> createReturn({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) => dao.createReturn(
    saleId: saleId,
    userId: userId,
    reason: reason,
    items: items,
  );

  Future<Result<int>> createReturnResult({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    try {
      final id = await createReturn(
        saleId: saleId,
        userId: userId,
        reason: reason,
        items: items,
      );
      return ok(id);
    } catch (e, st) {
      AppLogger.e('createReturn failed', error: e, stackTrace: st);
      return fail(
        'فشل إنشاء المرتجع',
        code: 'return_create',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }
}
