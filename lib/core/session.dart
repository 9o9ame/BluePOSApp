import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api.dart';
import 'appearance.dart';
import 'biometrics.dart';
import 'sale_attempt.dart';
import 'saved_accounts.dart';

class AppController extends ChangeNotifier {
  AppController(this.api, this.appearance, {BiometricAccess? biometric, SavedAccountsStore? savedAccounts})
      : biometric = biometric ?? BiometricAccess(),
        savedAccounts = savedAccounts ?? SavedAccountsStore();
  final BlueposApi api;
  final AppAppearance appearance;
  final BiometricAccess biometric;
  final SavedAccountsStore savedAccounts;
  String? _pendingMartCode;
  String? _pendingUsername;
  bool locked = false;
  bool unlocking = false;
  String? biometricMessage;
  Map<String, dynamic>? session;
  bool loading = true;

  bool get authenticated => session != null;
  String get tenantName => field(objectOf(session?['tenant'])['name'], 'BluePOS');
  String get branchName => field(objectOf(session?['branch'])['name'], 'Branch');
  String get warehouseName => field(objectOf(session?['warehouse'])['name'], 'Warehouse');
  String get userName => field(objectOf(session?['user'])['name'], 'Team member');
  String get currency => field(objectOf(session?['tenant'])['currency_code'], 'PKR');
  String get currentUserUlid => field(objectOf(session?['user'])['ulid']);
  bool get needsPasswordChange => session?['must_change_password'] == true;
  bool hasPermission(String key) {
    final raw = session?['permissions'];
    if (raw is! List) return false;
    return raw.contains(key);
  }

  Future<void> initialize() async {
    await appearance.load();
    await api.restore();
    try {
      final response = await api.get('/api/auth/me');
      _setSession(response);
      if (session != null && !needsPasswordChange) {
        // On a cold start show the login screen first, with an optional
        // biometric prompt for an approved and recoverable server session.
        locked = true;
      }
    } catch (_) {
      // An existing device cookie may expire; login remains available.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _setSession(dynamic response) {
    final parsed = objectOf(response);
    final actual = parsed.containsKey('user') ? parsed : objectOf(parsed['data']);
    if (actual['user'] is Map && actual['tenant'] is Map) {
      session = actual;
      appearance.apply(objectOf(actual['appearance']));
      notifyListeners();
    }
  }

  Future<Map<String, num>> _loginLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiFailure('LOCATION_REQUIRED',
          'Turn on phone location to sign in securely.', 0);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ApiFailure('LOCATION_REQUIRED',
          'BluePOS requires location permission for secure sign-in.', 0);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return {
      'location_latitude': position.latitude,
      'location_longitude': position.longitude,
      'location_accuracy': position.accuracy,
    };
  }

  Future<void> login(String tenant, String username, String password, bool remember) async {
    _pendingMartCode = tenant.trim();
    _pendingUsername = username.trim();
    final coords = await _loginLocation();
    final response = await api.post('/api/auth/login', {
      'tenant_code': tenant.trim(),
      'username': username.trim(),
      'password': password,
      'remember': remember,
      ...coords,
    });
    _setSession(response);
    if (session == null) {
      throw const ApiFailure('AUTH_RESPONSE', 'Invalid login session returned.', 502);
    }
    locked = false;
    await _rememberSuccessfulLogin();
    notifyListeners();
  }

  Future<void> _rememberSuccessfulLogin() async {
    final mart = _pendingMartCode;
    final username = _pendingUsername;
    _pendingMartCode = null;
    _pendingUsername = null;
    if (mart == null || username == null || currentUserUlid.length != 26) return;
    try {
      await savedAccounts.remember(martCode: mart, username: username,
        userUlid: currentUserUlid, displayName: userName);
    } catch (_) {
      // Optional local account picker failure must not block server authentication.
    }
  }

  Future<void> verifyMfa(String challenge, String code, bool trust, bool remember) async {
    final coords = await _loginLocation();
    final response = await api.post('/api/auth/mfa/verify', {
      'challenge_ulid': challenge,
      'code': code,
      'trust_device': trust,
      'remember': remember,
      ...coords,
    });
    _setSession(response);
    if (session == null) throw const ApiFailure('MFA_RESPONSE', 'Verification did not establish a session.', 502);
    locked = false;
    await _rememberSuccessfulLogin();
    notifyListeners();
  }

  Future<Map<String, dynamic>> resendMfa(String challenge) async {
    try {
      await api.post('/api/auth/mfa/resend', {'challenge_ulid': challenge});
      return {};
    } on ApiFailure catch (e) {
      if (e.key == 'MFA_REQUIRED' || e.key == 'EMAIL_DELIVERY_FAILED') {
        return e.extra;
      }
      rethrow;
    }
  }

  Future<void> changePassword(String current, String next) async {
    await api.post('/api/auth/change-password', {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
    final response = await api.get('/api/auth/me');
    _setSession(response);
  }

  Future<void> saveAppearance(Map<String, dynamic> config) async {
    final response = await api.patch('/api/auth/appearance', config);
    appearance.apply(objectOf(objectOf(response)['appearance']));
    session?['appearance'] = appearance.toJson();
  }

  Future<void> switchBranch(String branchUlid) async {
    if (session == null || branchUlid.length != 26) {
      throw const ApiFailure('INVALID_BRANCH', 'Choose an authorized branch.', 422);
    }
    final owner = currentUserUlid;
    final tenant = field(objectOf(session?['tenant'])['ulid']);
    final branch = field(objectOf(session?['branch'])['ulid']);
    final pendingSale = await const SaleAttemptStore().read(
      userUlid: owner, tenantUlid: tenant, branchUlid: branch,
    );
    final pendingQuotation = await const QuotationAttemptStore().read(
      userUlid: owner, tenantUlid: tenant, branchUlid: branch,
    );
    if (pendingSale != null || pendingQuotation != null) {
      throw const ApiFailure('UNCONFIRMED_DOCUMENT',
        'Resolve the earlier unconfirmed sale or quotation before switching branches.', 409);
    }
    // Backend verifies current device, active membership, branch and warehouse.
    final response = await api.post('/api/branches/$branchUlid/switch', {});
    _setSession(response);
    if (field(objectOf(session?['branch'])['ulid']) != branchUlid) {
      throw const ApiFailure('BRANCH_SWITCH_FAILED',
        'The server did not confirm the requested branch.', 502);
    }
  }

  /// Engage local screen lock before backgrounding; no content is displayed
  /// until the operating system verifies an enrolled biometric.
  Future<void> lockForBackground() async {
    if (authenticated && !needsPasswordChange && !unlocking &&
        await biometric.enabledFor(currentUserUlid)) {
      locked = true;
      notifyListeners();
    }
  }

  Future<bool> unlock() async {
    if (unlocking || session == null || !locked) return false;
    unlocking = true;
    biometricMessage = null;
    notifyListeners();
    try {
      if (!await biometric.confirm()) {
        biometricMessage = 'Biometric verification was cancelled or unavailable.';
        return false;
      }
      // Device permissions, session lifetime and tenancy still come from server.
      final response = await api.get('/api/auth/me');
      final validated = objectOf(response);
      final sessionValue = validated.containsKey('user') ? validated : objectOf(validated['data']);
      if (field(objectOf(sessionValue['user'])['ulid']) != currentUserUlid) {
        throw const ApiFailure('SESSION_CHANGED', 'Your session changed; sign in with password.', 401);
      }
      _setSession(response);
      locked = false;
      return true;
    } catch (e) {
      biometricMessage = e.toString();
      // For a revoked/expired session, require server login again.
      if (e is ApiFailure && (e.status == 401 || e.status == 403)) {
        await signInWithPassword();
      }
      return false;
    } finally {
      unlocking = false;
      notifyListeners();
    }
  }

  /// Login screen option for resuming an already-issued session after
  /// biometric opt-in. Cannot authenticate a first-time or expired account.
  Future<bool> biometricSignIn() async {
    if (!api.hasSavedSessionCookies) return false;
    final owner = await biometric.savedOwner();
    if (owner == null || owner.length != 26 || !await biometric.confirm()) return false;
    try {
      final response = await api.get('/api/auth/me');
      final source = objectOf(response);
      final actual = source.containsKey('user') ? source : objectOf(source['data']);
      if (field(objectOf(actual['user'])['ulid']) != owner) {
        throw const ApiFailure('SESSION_CHANGED',
          'This saved session belongs to another account. Use password login.', 401);
      }
      _setSession(response);
      locked = false;
      notifyListeners();
      return session != null;
    } on ApiFailure catch (error) {
      if (error.status == 401 || error.status == 403) await signInWithPassword();
      rethrow;
    }
  }

  Future<void> signInWithPassword() async {
    await api.clear();
    session = null;
    locked = false;
    biometricMessage = null;
    notifyListeners();
  }

  Future<bool> activateBiometrics() async {
    if (session == null || needsPasswordChange) return false;
    final activated = await biometric.enroll(currentUserUlid);
    notifyListeners();
    return activated;
  }

  Future<void> deactivateBiometrics() async {
    await biometric.disable();
    locked = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout', {});
    } catch (_) {
      // Even if network fails, remove all local session credentials.
    } finally {
      await api.clear();
      await biometric.disable();
      session = null;
      locked = false;
      notifyListeners();
    }
  }

  static String newIdempotencyKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final suffix = bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return 'mobile-${DateTime.now().toUtc().microsecondsSinceEpoch}-$suffix';
  }
}
