import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api.dart';
import 'appearance.dart';

class AppController extends ChangeNotifier {
  AppController(this.api, this.appearance);
  final BlueposApi api;
  final AppAppearance appearance;
  Map<String, dynamic>? session;
  bool loading = true;

  bool get authenticated => session != null;
  String get tenantName => field(objectOf(session?['tenant'])['name'], 'BluePOS');
  String get branchName => field(objectOf(session?['branch'])['name'], 'Branch');
  String get warehouseName => field(objectOf(session?['warehouse'])['name'], 'Warehouse');
  String get userName => field(objectOf(session?['user'])['name'], 'Team member');
  String get currency => field(objectOf(session?['tenant'])['currency_code'], 'PKR');
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

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout', {});
    } catch (_) {
      // Even if network fails, remove all local session credentials.
    } finally {
      await api.clear();
      session = null;
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
