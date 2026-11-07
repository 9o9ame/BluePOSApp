import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/biometrics.dart';
import 'package:bluepos_app/core/saved_accounts.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoBiometricHardware extends BiometricAccess {
  @override
  Future<String?> savedOwner() async => null;
  @override
  Future<bool> available() async => false;
}

class _RememberedLogins extends SavedAccountsStore {
  @override
  Future<List<SavedLoginAccount>> list() async => [
    SavedLoginAccount(
      martCode: 'ALPHA',
      username: 'cashier',
      userUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      displayName: 'Cashier',
      lastUsedAt: DateTime.utc(2026, 11, 5),
    ),
  ];
}

void main() {
  testWidgets('circular login shows approved copy without extra footer lines',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(),
      biometric: _NoBiometricHardware(), savedAccounts: _RememberedLogins());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('POS & ERP'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Mobile POS & ERP'), findsNothing);
    expect(find.text('Sign in to your secure workspace'), findsNothing);
    expect(find.text('Fingerprint / Face Unlock'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('biometric button is tappable and explains opt-in', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(),
      biometric: _NoBiometricHardware(), savedAccounts: _RememberedLogins());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fingerprint / Face Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in first to enable biometrics.'),
      findsOneWidget);
  });

  testWidgets('saved accounts are available without showing saved passwords',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(),
      biometric: _NoBiometricHardware(), savedAccounts: _RememberedLogins());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(find.text('Saved accounts'), findsOneWidget);
    expect(find.textContaining('Passwords are not stored.'), findsOneWidget);
    await tester.tap(find.text('Cashier'));
    await tester.pumpAndSettle();
    expect(find.text('Saved accounts'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'ALPHA');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'cashier');
    expect(tester.takeException(), isNull);
  });


  for (final size in const [
    Size(320, 680),
    Size(360, 780),
    Size(393, 851),
  ]) {
    testWidgets('login button corners stay within circle at ${size.width}px',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final app = AppController(BlueposApi(), AppAppearance(),
        biometric: _NoBiometricHardware(), savedAccounts: _RememberedLogins());
      await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
      await tester.pumpAndSettle();

      final circle = tester.getRect(find.byKey(const ValueKey('login-circle')));
      final button = tester.getRect(find.byKey(const ValueKey('login-submit')));
      final radius = circle.width / 2 - 10;
      for (final corner in [
        button.topLeft, button.topRight, button.bottomLeft, button.bottomRight,
      ]) {
        expect((corner - circle.center).distance, lessThan(radius),
          reason: 'Login button must stay within circular panel at ${size.width}px');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('circular form avoids overflow on compact Android phones',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 680));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(),
      biometric: _NoBiometricHardware(), savedAccounts: _RememberedLogins());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
