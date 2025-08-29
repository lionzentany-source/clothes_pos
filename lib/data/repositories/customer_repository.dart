import 'package:clothes_pos/data/datasources/customer_dao.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';

/// Repository for managing customer operations
class CustomerRepository {
  final CustomerDao dao;

  CustomerRepository(this.dao);

  /// Get all customers with pagination
  Future<List<Customer>> listAll({int limit = 100, int offset = 0}) async {
    return dao.listAll(limit: limit, offset: offset);
  }

  /// Search customers by name or phone number
  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    return dao.search(query, limit: limit, offset: offset);
  }

  /// Search customers with Result wrapper for safer error handling
  Future<Result<List<Customer>>> searchResult(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final customers = await search(query, limit: limit, offset: offset);
      return ok(customers);
    } catch (e, st) {
      AppLogger.e(
        'CustomerRepository.searchResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'تعذر البحث عن العملاء',
        code: 'customer_search',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Get customer by ID
  Future<Customer?> getById(int id) async {
    return dao.getById(id);
  }

  /// Get customer by ID with Result wrapper
  Future<Result<Customer?>> getByIdResult(int id) async {
    try {
      final customer = await getById(id);
      return ok(customer);
    } catch (e, st) {
      AppLogger.e(
        'CustomerRepository.getByIdResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'تعذر تحميل بيانات العميل',
        code: 'customer_get',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Get customer by phone number
  Future<Customer?> getByPhoneNumber(String phoneNumber) async {
    return dao.getByPhoneNumber(phoneNumber);
  }

  /// Create a new customer
  Future<int> create(Customer customer, {int? userId}) async {
    final id = await dao.insert(customer);

    // Log audit trail
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'customer:$id',
        field: 'create',
        newValue: customer.name,
      );
    } catch (e) {
      AppLogger.w('Failed to log customer creation audit', error: e);
    }

    return id;
  }

  /// Create a new customer with Result wrapper
  Future<Result<int>> createResult(Customer customer, {int? userId}) async {
    try {
      // Validate phone number uniqueness if provided
      if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty) {
        final exists = await dao.phoneNumberExists(customer.phoneNumber!);
        if (exists) {
          return fail(
            'رقم الهاتف مستخدم بالفعل',
            code: 'phone_exists',
            retryable: false,
          );
        }
      }

      final id = await create(customer, userId: userId);
      return ok(id);
    } catch (e, st) {
      AppLogger.e(
        'CustomerRepository.createResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'فشل في إنشاء العميل',
        code: 'customer_create',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Update an existing customer
  Future<void> update(Customer customer, {int? userId}) async {
    await dao.update(customer);

    // Log audit trail
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'customer:${customer.id}',
        field: 'update',
        newValue: customer.name,
      );
    } catch (e) {
      AppLogger.w('Failed to log customer update audit', error: e);
    }
  }

  /// Update an existing customer with Result wrapper
  Future<Result<void>> updateResult(Customer customer, {int? userId}) async {
    try {
      if (customer.id == null) {
        return fail(
          'معرف العميل مطلوب للتحديث',
          code: 'customer_id_required',
          retryable: false,
        );
      }

      // Validate phone number uniqueness if provided
      if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty) {
        final exists = await dao.phoneNumberExists(
          customer.phoneNumber!,
          excludeId: customer.id,
        );
        if (exists) {
          return fail(
            'رقم الهاتف مستخدم بالفعل',
            code: 'phone_exists',
            retryable: false,
          );
        }
      }

      await update(customer, userId: userId);
      return ok(null);
    } catch (e, st) {
      AppLogger.e(
        'CustomerRepository.updateResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'فشل في تحديث العميل',
        code: 'customer_update',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Delete a customer
  Future<void> delete(int id, {int? userId}) async {
    await dao.delete(id);

    // Log audit trail
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'customer:$id',
        field: 'delete',
      );
    } catch (e) {
      AppLogger.w('Failed to log customer deletion audit', error: e);
    }
  }

  /// Delete a customer with Result wrapper
  Future<Result<void>> deleteResult(int id, {int? userId}) async {
    try {
      await delete(id, userId: userId);
      return ok(null);
    } catch (e, st) {
      AppLogger.e(
        'CustomerRepository.deleteResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'فشل في حذف العميل',
        code: 'customer_delete',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Check if phone number exists
  Future<bool> phoneNumberExists(String phoneNumber, {int? excludeId}) async {
    return dao.phoneNumberExists(phoneNumber, excludeId: excludeId);
  }

  /// Get customer count
  Future<int> getCount() async {
    return dao.getCount();
  }

  /// Get customers with sales statistics
  Future<List<Map<String, Object?>>> getCustomersWithSalesStats({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return dao.getCustomersWithSalesStats(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Get top customers by spending
  Future<List<Map<String, Object?>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    return getCustomersWithSalesStats(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: 0,
    );
  }

  /// Find or create customer by phone number
  Future<Customer> findOrCreateByPhone(
    String phoneNumber,
    String name, {
    int? userId,
  }) async {
    // Try to find existing customer
    final existing = await getByPhoneNumber(phoneNumber);
    if (existing != null) {
      return existing;
    }

    // Create new customer
    final customer = Customer(name: name, phoneNumber: phoneNumber);
    final id = await create(customer, userId: userId);
    return customer.copyWith(id: id);
  }
}
