import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// This only unlocks an EXISTING, server-authorized Sanctum session.
/// It never substitutes for password, tenant MFA, or device approval.
class BiometricAccess {
  BiometricAccess({FlutterSecureStorage? storage, LocalAuthentication? auth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _auth = auth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;
  static const _ownerKey = 'bp_biometric_user_v1';

  Future<bool> available() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> supportedTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> enabledFor(String userUlid) async {
    if (userUlid.length != 26) return false;
    return (await _storage.read(key: _ownerKey)) == userUlid;
  }

  Future<bool> confirm() async {
    if (!await available()) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock your approved BluePOS session',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enroll(String userUlid) async {
    if (userUlid.length != 26 || !await confirm()) return false;
    await _storage.write(key: _ownerKey, value: userUlid);
    return true;
  }

  Future<void> disable() => _storage.delete(key: _ownerKey);
}
