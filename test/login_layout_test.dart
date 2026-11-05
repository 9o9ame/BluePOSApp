import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/biometrics.dart';
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

void main() {
  testWidgets('circular login fields remain accessible on narrow phones', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(), biometric: _NoBiometricHardware());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Fingerprint / Face Unlock'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login scales the circular form on compact Android screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 680));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance(), biometric: _NoBiometricHardware());
    await tester.pumpWidget(MaterialApp(home: LoginScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
