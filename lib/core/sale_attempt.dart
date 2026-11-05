import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pending invoices are encrypted locally and associated with the exact user,
/// tenant and branch. Never generate a new idempotency key for an unconfirmed save.
class SaleAttemptStore {
  const SaleAttemptStore({FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;
  final FlutterSecureStorage _storage;
  static const key = 'bluepos_unconfirmed_sale_v1';

  Future<void> write({required String userUlid, required String tenantUlid,
      required String branchUlid, required String attemptKey,
      required Map<String, dynamic> payload}) async {
    await _storage.write(key: key, value: jsonEncode({
      'user': userUlid, 'tenant': tenantUlid, 'branch': branchUlid,
      'key': attemptKey, 'payload': payload,
    }));
  }

  Future<Map<String, dynamic>?> read({required String userUlid,
      required String tenantUlid, required String branchUlid}) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final result = jsonDecode(raw);
      if (result is! Map) return null;
      final data = Map<String, dynamic>.from(result);
      if (data['user'] != userUlid || data['tenant'] != tenantUlid ||
          data['branch'] != branchUlid) return null;
      if (data['payload'] is! Map || data['key'] is! String) return null;
      return data;
    } catch (_) { return null; }
  }

  Future<void> clear() => _storage.delete(key: key);
}
