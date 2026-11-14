import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reference 09 More shows server tenant and permitted groups',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'tenant': {'name': 'Authorized Demo Tenant'},
      'branch': {'name': 'Authorized Branch'},
      'permissions': ['products.view'],
    };
    await tester.pumpWidget(MaterialApp(
      theme: app.appearance.data(Brightness.light),
      home: Scaffold(body: ModulesScreen(app: app, navigate: (_) {})),
    ));
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Authorized Demo Tenant'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-Definition')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-Daily Entries')), findsNothing);
    expect(tester.takeException(), isNull);
    await app.api.close();
  });

  testWidgets('reference 08 Main Menu retains permission-aware routing',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'tenant': {'name': 'Authorized Demo Tenant'},
      'permissions': ['products.view'],
    };
    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModulesScreen(
        app: app, navigate: (tab) => selected = tab)),
    ));
    await tester.tap(find.byTooltip('Open Main Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Main Menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-Definition')), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    await tester.tap(find.text('Products'));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
    await app.api.close();
  });
}
