import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Non-secret account picker metadata. Never persist passwords or MFA codes.
class SavedLoginAccount {
  const SavedLoginAccount({
    required this.martCode,
    required this.username,
    required this.userUlid,
    required this.displayName,
    required this.lastUsedAt,
  });

  final String martCode;
  final String username;
  final String userUlid;
  final String displayName;
  final DateTime lastUsedAt;

  String get key => '${martCode.toLowerCase()}::${username.toLowerCase()}';

  Map<String, dynamic> toJson() => {
    'mart_code': martCode,
    'username': username,
    'user_ulid': userUlid,
    'display_name': displayName,
    'last_used_at': lastUsedAt.toUtc().toIso8601String(),
  };

  static SavedLoginAccount? fromJson(dynamic value) {
    if (value is! Map) return null;
    final mart = value['mart_code'];
    final user = value['username'];
    final ulid = value['user_ulid'];
    final name = value['display_name'];
    final used = value['last_used_at'];
    if (mart is! String || mart.trim().isEmpty || mart.length > 100 ||
        user is! String || user.trim().isEmpty || user.length > 100 ||
        ulid is! String || !RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid) ||
        name is! String || name.length > 150 || used is! String) {
      return null;
    }
    final time = DateTime.tryParse(used);
    if (time == null) return null;
    return SavedLoginAccount(
      martCode: mart.trim(),
      username: user.trim(),
      userUlid: ulid,
      displayName: name.trim(),
      lastUsedAt: time.toUtc(),
    );
  }
}

class SavedAccountsStore {
  SavedAccountsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'bp_remembered_logins_v1';
  static const maxSavedAccounts = 8;

  Future<List<SavedLoginAccount>> list() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null) return const [];
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      final accounts = decoded.map(SavedLoginAccount.fromJson)
          .whereType<SavedLoginAccount>().toList();
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      final unique = <String, SavedLoginAccount>{};
      for (final account in accounts) {
        unique.putIfAbsent(account.key, () => account);
      }
      return unique.values.take(maxSavedAccounts).toList();
    } catch (_) {
      // Damaged/unavailable local secure storage must not block authentication.
      return const [];
    }
  }

  Future<void> remember({
    required String martCode,
    required String username,
    required String userUlid,
    required String displayName,
  }) async {
    final now = DateTime.now().toUtc();
    final candidate = SavedLoginAccount(
      martCode: martCode.trim(),
      username: username.trim(),
      userUlid: userUlid,
      displayName: displayName,
      lastUsedAt: now,
    );
    if (SavedLoginAccount.fromJson(candidate.toJson()) == null) return;
    final accounts = await list();
    final updated = [candidate, ...accounts.where((account) => account.key != candidate.key)]
        .take(maxSavedAccounts).map((account) => account.toJson()).toList();
    await _storage.write(key: _key, value: jsonEncode(updated));
  }

  Future<void> forget(SavedLoginAccount account) async {
    final updated = (await list()).where((item) => item.key != account.key)
        .map((item) => item.toJson()).toList();
    if (updated.isEmpty) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: jsonEncode(updated));
    }
  }
}
