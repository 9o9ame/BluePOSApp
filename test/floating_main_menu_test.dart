import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('floating menu expands permitted Daily Entries and navigates',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance());
    // A local widget-test session, never used by production authentication.
    app.session = {
      'permissions': ['sales.view', 'sales.create'],
      'entitlements': {'features': ['sales']},
    };
    var closed = 0;
    int? destination;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(
        width: 320,
        child: ModulesScreen(
          app: app,
          navigate: (index) => destination = index,
          drawerMode: true,
          onDrawerAction: () => closed++,
        ),
      )),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-main-menu-list')),
      findsOneWidget);
    expect(find.text('Main Menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('drawer-group-Daily Entries')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('drawer-action-New Sale')),
      findsNothing);

    await tester.tap(find.byKey(
      const ValueKey('drawer-group-Daily Entries')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-action-New Sale')),
      findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drawer-action-New Sale')));
    await tester.pump();
    expect(closed, 1);
    expect(destination, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await app.api.close();
  });

  testWidgets('floating drawer search can open without permission leaks',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ModulesScreen(app: app, drawerMode: true,
        navigate: (_) {}))));
    await tester.tap(find.byKey(const ValueKey('drawer-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drawer-search-input')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('drawer-action-New Sale')),
      findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await app.api.close();
  });
}
