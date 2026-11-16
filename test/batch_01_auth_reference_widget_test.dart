import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/auth_reference_chrome.dart';
import 'package:bluepos_app/screens/splash.dart';
import 'package:bluepos_app/screens/password_recovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('01 Splash uses reference logo, loading dots and waves',
      (tester) async {
    final appearance = AppAppearance();
    await tester.pumpWidget(MaterialApp(
      home: BlueposSplash(appearance: appearance)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('splash-cart-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-wordmark')), findsOneWidget);
    expect(find.text('Complete Business Management'), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loading-dots')), findsOneWidget);
    expect(find.byType(AuthReferenceWaves), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('05 Recovery validates tenant+username locally without a request',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    await tester.pumpWidget(MaterialApp(
      home: PasswordRecoveryScreen(app: app)));
    await tester.tap(find.byKey(const ValueKey('recovery-submit')));
    await tester.pump();
    expect(find.text('Tenant code and username are required.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-tenant')), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-username')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.api.close();
  });

  testWidgets('shared auth chrome uses theme rather than illustration assets',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Column(children: [
        AuthReferenceBrand(),
        AuthReferenceWaves(height: 80),
      ]))));
    expect(find.text('BluePOS'), findsOneWidget);
    expect(find.byType(AuthReferenceWaves), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
