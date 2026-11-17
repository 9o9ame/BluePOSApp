import 'dart:convert';

import 'package:bluepos_app/core/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cookieKey = 'bluepos_pk_mobile_auth_cookies_v1';
  const device = '01JAAABBBCCCDDDEEEFFFGGGHH.test-device-secret';

  test('logout clears login session but keeps enrolled device credential',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      cookieKey: jsonEncode({
        'bluepos_device': device,
        'bluepos-session': 'old-authenticated-session',
        'XSRF-TOKEN': 'old-xsrf',
      }),
    });
    final api = BlueposApi();
    await api.restore();
    expect(api.hasSavedSessionCookies, isTrue);
    expect(api.hasSavedDeviceCredential, isTrue);

    await api.clear();
    expect(api.hasSavedSessionCookies, isFalse);
    expect(api.hasSavedDeviceCredential, isTrue);

    // A new app instance restores only device identity, never the old login.
    final reopened = BlueposApi();
    await reopened.restore();
    expect(reopened.hasSavedDeviceCredential, isTrue);
    expect(reopened.hasSavedSessionCookies, isFalse);
    await api.close();
    await reopened.close();
  });

  test('explicit forget device clears the last trusted credential', () async {
    FlutterSecureStorage.setMockInitialValues({
      cookieKey: jsonEncode({'bluepos_device': device}),
    });
    final api = BlueposApi();
    await api.restore();
    expect(api.hasSavedDeviceCredential, isTrue);

    await api.clear(forgetDevice: true);
    expect(api.hasSavedDeviceCredential, isFalse);
    expect(api.hasSavedSessionCookies, isFalse);

    final reopened = BlueposApi();
    await reopened.restore();
    expect(reopened.hasSavedDeviceCredential, isFalse);
    await api.close();
    await reopened.close();
  });
}
