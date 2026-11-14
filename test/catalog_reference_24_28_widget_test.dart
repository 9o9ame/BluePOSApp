import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/sale_schemes.dart';
import 'package:bluepos_app/screens/parties.dart';
import 'package:bluepos_app/screens/customer_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ScreensStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/sale-schemes') return {'data': [
      {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        'name': 'Authorized Promotion', 'scheme_type': 'reward_product',
        'apply_mode': 'sale', 'is_active': true, 'starts_on': '2026-11-01'},
    ]};
    if (path == '/api/parties?type=customer') return {'data': [
      {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
        'name': 'Test Customer', 'code': 'C-101',
        'area': 'Lahore', 'mobile': '0000000000',
        'is_active': true},
    ]};
    if (path.startsWith('/api/parties/')) return {'data': {
      'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
      'name': 'Test Customer', 'code': 'C-101',
      'area': 'Lahore', 'mobile': '0000000000',
      'credit_limit_amount': '500.0000', 'is_active': true,
    }};
    if (path == '/api/coa/account-types') return {'data': [
      {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAX',
        'name': 'Receivable', 'is_active': true},
    ]};
    return {'data': []};
  }
}

void main() {
  late ScreensStubApi api;
  late AppController app;
  setUp(() {
    api = ScreensStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'sale_schemes.view', 'customers.view', 'customers.create',
      'customers.edit',
    ]};
  });
  tearDown(() async => api.close());

  testWidgets('24 Sale Schemes shows only server-supplied promotion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: SaleSchemesScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('Authorized Promotion'), findsOneWidget);
    expect(find.text('Buy 2 Get 1 Free'), findsNothing);
    expect(find.byKey(const ValueKey('sale-scheme-filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('25 Add Sale Scheme is non-submittable reference',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AddSaleSchemeReferenceScreen()));
    final save = find.byKey(const ValueKey('sale-scheme-save-disabled'));
    await tester.scrollUntilVisible(save, 160,
      scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('26 Customers list shows authorized customer data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: PartyDirectory(
      app: app, type: 'customer')));
    await tester.pumpAndSettle();
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('C-101'), findsOneWidget);
    expect(find.byKey(const ValueKey('party-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('27 Add Customer uses full page form and required account type',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: PartyDirectory(
      app: app, type: 'customer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('party-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Customer'), findsWidgets);
    expect(find.byKey(const ValueKey('party-editor-code')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-editor-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-editor-area')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('28 Customer Detail shows real data and no fake balance',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CustomerDetailView(customer: const {
        'name': 'Test Customer', 'code': 'C-101',
        'mobile': '0000000000', 'area': 'Lahore',
        'credit_limit_amount': '500.0000',
      }))));
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('500.0000'), findsOneWidget);
    expect(find.text('Rs 278,900.00'), findsNothing);
    expect(find.byKey(const ValueKey('customer-detail-edit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('customer payload requires real account type ULID', () {
    expect(() => partyPayload(type: 'customer', code: 'C-101',
      name: 'Test Customer', accountTypeUlid: 'invalid', isActive: true),
      throwsFormatException);
    final payload = partyPayload(type: 'customer', code: ' c-101 ',
      name: 'Test Customer',
      accountTypeUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAX',
      isActive: true, area: ' Lahore ');
    expect(payload['code'], 'C-101');
    expect(payload['area'], 'Lahore');
    expect(payload.containsKey('opening_balance'), isFalse);
    expect(payload.containsKey('credit_limit_amount'), isFalse);
  });
}
