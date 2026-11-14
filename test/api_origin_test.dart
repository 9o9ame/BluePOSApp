import 'package:bluepos_app/core/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile API uses the canonical HTTPS BluePOS domain', () {
    final origin = Uri.parse(apiOrigin);
    expect(origin.scheme, 'https');
    expect(origin.host, 'bluepos.pk');
    expect(origin.path, isEmpty);
    expect(origin.hasQuery, isFalse);
    expect(origin.hasFragment, isFalse);
    expect(origin.resolve('/sanctum/csrf-cookie').toString(),
        'https://bluepos.pk/sanctum/csrf-cookie');
    expect(origin.resolve('/api/auth/me').toString(),
        'https://bluepos.pk/api/auth/me');
  });
}
