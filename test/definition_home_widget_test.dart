import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('newer Definition Home preserves image order and authorization',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'tenant': {'name': 'Demo Tenant'},
      'permissions': [
        'products.view', 'customers.view', 'suppliers.view',
        'categories.view', 'units.view',
      ],
    };
    int? selected;
    await tester.pumpWidget(MaterialApp(
      theme: app.appearance.data(Brightness.light),
      home: Scaffold(body: ModulesScreen(
        app: app, navigate: (value) => selected = value)),
    ));

    await tester.tap(find.byKey(const ValueKey('menu-Definition')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('approved-definition-home')), findsOneWidget);

    expect(find.byKey(const ValueKey('definition-Products')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Customers')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Suppliers')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Categories')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Units')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Brands')), findsNothing);
    expect(find.byKey(const ValueKey('definition-Stock Taking')), findsNothing);

    final productsTop = tester.getTopLeft(
      find.byKey(const ValueKey('definition-Products'))).dy;
    final customersTop = tester.getTopLeft(
      find.byKey(const ValueKey('definition-Customers'))).dy;
    expect(productsTop, lessThan(customersTop));

    await tester.tap(find.byKey(const ValueKey('definition-Products')));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
    await app.api.close();
  });

  testWidgets('Definition Home can return to More without changing tabs',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'tenant': {'name': 'Demo Tenant'},
      'permissions': ['products.view'],
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModulesScreen(app: app, navigate: (_) {})),
    ));
    await tester.tap(find.byKey(const ValueKey('menu-Definition')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to More'));
    await tester.pumpAndSettle();
    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const ValueKey('approved-definition-home')), findsNothing);
    expect(tester.takeException(), isNull);
    await app.api.close();
  });
}
