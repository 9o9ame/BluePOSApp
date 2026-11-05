import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A pending document request must retain its original idempotency key across
/// process restarts. The encrypted payload is confined to the exact user,
/// tenant and branch; no client-selected tenant or branch is sent to the API.
class DocumentAttemptStore {
  const DocumentAttemptStore({
    required this.storageKey,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final String storageKey;
  final FlutterSecureStorage _storage;

  Future<void> write({
    required String userUlid,
    required String tenantUlid,
    required String branchUlid,
    required String attemptKey,
    required Map<String, dynamic> payload,
  }) async {
    final ulid = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
    if (!ulid.hasMatch(userUlid) ||
        !ulid.hasMatch(tenantUlid) ||
        !ulid.hasMatch(branchUlid) ||
        attemptKey.trim().isEmpty ||
        attemptKey.length > 120) {
      throw const FormatException('Invalid pending document context.');
    }
    await _storage.write(key: storageKey, value: jsonEncode({
      'user': userUlid,
      'tenant': tenantUlid,
      'branch': branchUlid,
      'key': attemptKey,
      'payload': payload,
    }));
  }

  Future<Map<String, dynamic>?> read({
    required String userUlid,
    required String tenantUlid,
    required String branchUlid,
  }) async {
    try {
      final raw = await _storage.read(key: storageKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      if (data['user'] != userUlid ||
          data['tenant'] != tenantUlid ||
          data['branch'] != branchUlid ||
          data['payload'] is! Map ||
          data['key'] is! String) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: storageKey);
}

/// Keeps the existing Sales Invoice storage key to preserve pending attempts.
class SaleAttemptStore extends DocumentAttemptStore {
  const SaleAttemptStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : super(storageKey: key, storage: storage);

  static const key = 'bluepos_unconfirmed_sale_v1';
}

/// Quotation retries never overwrite or clear an unconfirmed Sales Invoice.
class QuotationAttemptStore extends DocumentAttemptStore {
  const QuotationAttemptStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : super(storageKey: key, storage: storage);

  static const key = 'bluepos_unconfirmed_quotation_v1';
}


/// Manual voucher creation is server-idempotent and its pending request must
/// not be confused with sale, quotation or other voucher attempts.
class VoucherAttemptStore extends DocumentAttemptStore {
  const VoucherAttemptStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : super(storageKey: key, storage: storage);

  static const key = 'bluepos_unconfirmed_voucher_v1';
}
