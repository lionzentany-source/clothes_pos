import 'dart:async';
import 'dart:convert';

import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/interfaces/invoice_repository.dart';

/// Abstract sync service used to enqueue items (invoices) and drive
/// background synchronization with the remote server.
abstract class SyncService {
  /// Enqueue a sale payload for later synchronization.
  Future<void> enqueueInvoice(Map<String, Object?> invoicePayload);

  /// Trigger a manual sync attempt for pending items.
  Future<void> syncPending();

  /// Start background sync loop (no-op if already started).
  Future<void> start();

  /// Stop background sync loop.
  Future<void> stop();

  /// Current status (idle, syncing, error)
  String get status;
}

/// Very small local queue implementation that persists pending invoices to
/// a local table and attempts to sync using [SalesRepository]. This is a
/// skeleton intended for gradual hardening.
class LocalQueueSyncService implements SyncService {
  final DatabaseHelper _db;
  final InvoiceRepository _invoiceRepo;
  Timer? _timer;
  String _status = 'idle';

  // Controls max attempts before marking failed
  final int maxAttempts;

  // Base backoff seconds (exponential multiplier)
  final int baseBackoffSeconds;

  LocalQueueSyncService(
    this._db,
    this._invoiceRepo, {
    this.maxAttempts = 5,
    this.baseBackoffSeconds = 2,
  });

  @override
  String get status => _status;

  @override
  Future<void> enqueueInvoice(Map<String, Object?> invoicePayload) async {
    final db = await _db.database;
    final payloadJson = jsonEncode(invoicePayload);
    await db.insert('pending_invoices', {
      'payload': payloadJson,
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
      'status': 'pending',
    });
  }

  @override
  Future<void> start() async {
    if (_timer != null) return;
    // Poll frequently but syncPending will respect attempts/backoff
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        await syncPending();
      } catch (_) {}
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _status = 'idle';
  }

  @override
  Future<void> syncPending() async {
    _status = 'syncing';
    try {
      final db = await _db.database;
      // Select pending items; we'll fetch a batch and process respecting attempts/backoff
      final rows = await db.query(
        'pending_invoices',
        where: 'status = ?',
        whereArgs: ['pending'],
        limit: 20,
      );

      for (final r in rows) {
        final id = r['id'] as int?;
        final attempts = (r['attempts'] as int?) ?? 0;
        final payloadText = r['payload'] as String? ?? '';

        // Check backoff: if attempts > 0, compute next allowed time in-memory
        // (we don't persist next_attempt_at in schema). If attempts is high,
        // skip briefly to allow exponential backoff by delaying processing.
        if (attempts > 0) {
          final waitSeconds = baseBackoffSeconds * (1 << (attempts - 1));
          // If the record was just updated very recently, skip processing this cycle
          final createdAtStr = r['created_at'] as String?;
          if (createdAtStr != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr);
              final minAllowed = createdAt.add(Duration(seconds: waitSeconds));
              if (DateTime.now().isBefore(minAllowed)) {
                // skip this record for now
                continue;
              }
            } catch (_) {
              // ignore parse errors and proceed
            }
          }
        }

        Map<String, Object?> payload;
        try {
          payload = payloadText.isNotEmpty
              ? (jsonDecode(payloadText) as Map<String, dynamic>)
                    .cast<String, Object?>()
              : <String, Object?>{};
        } catch (e) {
          // Malformed payload -> mark as failed immediately
          if (id != null) {
            await db.update(
              'pending_invoices',
              {'status': 'failed'},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          continue;
        }

        try {
          await _invoiceRepo.createInvoiceFromPayload(payload);
          if (id != null) {
            await db.update(
              'pending_invoices',
              {'status': 'synced'},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        } catch (e) {
          final newAttempts = attempts + 1;
          final isFailed = newAttempts >= maxAttempts;
          if (id != null) {
            await db.update(
              'pending_invoices',
              {
                'attempts': newAttempts,
                'status': isFailed ? 'failed' : 'pending',
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }

      _status = 'idle';
    } catch (e) {
      _status = 'error';
      rethrow;
    }
  }
}
