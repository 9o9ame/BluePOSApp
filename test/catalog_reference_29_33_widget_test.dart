import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/parties.dart';
import 'package:bluepos_app/screens/supplier_detail.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:bluepos_app/screens/sales_invoice_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SupplierStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/parties?type=vendor') return {'data': [
      {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        'name': 'Verified Supplier', 'code': 'S-001',
        'area': 'Lahore', 'mobile': '0000000000', 'is_active': true},
    ]};
    if (path == '/api/coa/account-types') return {'data': [
      {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
        'name': 'Payables', 'is_active': true},
    ]};
    if (path.startsWith('/api/parties/')) return {'data': {
      'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      'name': 'Verified Supplier', 'code': 'S-001',
      'mobile': '0000000000', 'area': 'Lahore',
      'is_active': true,
    }};
    return {'data': []};
  }
}

void main() {
  late SupplierStubApi api;
  late AppController app;
  setUp(() {
    api = SupplierStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'suppliers.view', 'suppliers.create', 'suppliers.edit',
      'sales.view', 'sales.create', 'purchases.view',
    ]};
  });
  tearDown(() async => api.close());

  testWidgets('29 Suppliers shows tenant API rows and authorized Add',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PartyDirectory(app: app, type: 'vendor')));
    await tester.pumpAndSettle();
    expect(find.text('Verified Supplier'), findsOneWidget);
    expect(find.text('S-001'), findsOneWidget);
    expect(find.byKey(const ValueKey('party-filter')), findsOneWidget);
    expect(find.text('Add Supplier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('30 Supplier Details hides unavailable payable summary',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SupplierDetailView(supplier: {
        'name': 'Verified Supplier', 'code': 'S-001',
        'mobile': '0000000000', 'area': 'Lahore',
      }))));
    expect(find.text('Verified Supplier'), findsOneWidget);
    expect(find.text('Recent Purchases'), findsOneWidget);
    expect(find.text('Rs 278,900.00'), findsNothing);
    expect(find.byKey(const ValueKey('supplier-detail-edit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('31 Supplier form has backend-required account type and area',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PartyDirectory(app: app, type: 'vendor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('party-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Supplier'), findsWidgets);
    expect(find.byKey(const ValueKey('party-editor-code')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-editor-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-editor-area')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('32 Daily Entries uses existing permission-scoped launcher',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModulesScreen(app: app, navigate: (_) {}))));
    await tester.tap(find.byKey(const ValueKey('menu-Daily Entries')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('approved-daily-entries-home')),
      findsOneWidget);
    expect(find.text('Sales Invoices'), findsOneWidget);
    expect(find.text('Purchase Invoices'), findsOneWidget);
    expect(find.text('Expense Vouchers'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('33 Sales Invoice reuses existing POS editor', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SalesInvoiceEntryScreen(app: app)));
    await tester.pump();
    expect(find.text('Create Sales Invoice'), findsOneWidget);
    expect(find.text('POS (Sales)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('supplier payload keeps public account type and no fake payable', () {
    final payload = partyPayload(type: 'vendor', code: 's-001',
      name: 'Supplier', area: ' Lahore ', isActive: true,
      accountTypeUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAW');
    expect(payload['code'], 'S-001');
    expect(payload['area'], 'Lahore');
    expect(payload.containsKey('payable_balance'), isFalse);
    expect(payload.containsKey('opening_balance'), isFalse);
  });
}
