import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('08 Main Menu and 09 More remain independently reachable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 880));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance());
    final menuMode = ValueNotifier<bool>(false);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModulesScreen(
        app: app, menuMode: menuMode, navigate: (_) {}))));
    await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-to-main-menu')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('switch-to-main-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Main Menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-to-more')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('switch-to-more')));
    await tester.pumpAndSettle();
    expect(find.text('More'), findsOneWidget);

    menuMode.value = true; // The shell's hamburger action.
    await tester.pumpAndSettle();
    expect(find.text('Main Menu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    menuMode.dispose();
    await app.api.close();
  });
}
