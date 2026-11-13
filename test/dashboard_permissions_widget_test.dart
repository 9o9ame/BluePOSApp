import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no sales or product grants hide all related dashboard actions',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'permissions': <String>[],
      'tenant': {'name': 'Test tenant'},
      'branch': {'name': 'Test branch'},
      'warehouse': {'name': 'Test warehouse'},
      'user': {'name': 'Read only'},
      'entitlements': {'features': ['sales', 'catalog']},
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: DashboardScreen(app: app, navigate: (_) {}),
    )));
    await tester.pumpAndSettle();

    expect(find.text('New Sale'), findsNothing);
    expect(find.text('Invoices'), findsNothing);
    expect(find.text('Recent invoices'), findsNothing);
    expect(find.text('Products'), findsNothing);
    expect(find.text('Business at a glance'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales.create without sales.view shows sale but not history',
      (tester) async {
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'permissions': ['sales.create'],
      'tenant': {'name': 'Test tenant'},
      'branch': {'name': 'Test branch'},
      'warehouse': {'name': 'Test warehouse'},
      'user': {'name': 'Sales staff'},
      'entitlements': {'features': ['sales']},
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: DashboardScreen(app: app, navigate: (_) {}),
    )));
    await tester.pumpAndSettle();

    expect(find.text('New Sale'), findsWidgets);
    expect(find.text('Invoices'), findsNothing);
    expect(find.text('Recent invoices'), findsNothing);
    expect(find.text('Business at a glance'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
