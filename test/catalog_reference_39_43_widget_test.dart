import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/returns.dart';
import 'package:bluepos_app/screens/money_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReferenceStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/purchase-returns?')) {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
          'document_number': 'PR-00186',
          'return_date': '2026-11-14',
          'status': 'draft', 'grand_total': '6480.0000',
          'supplier': {'name': 'Authorized supplier'}},
      ], 'meta': {'total': 1}};
    }
    if (path == '/api/purchase-returns/01ARZ3NDEKTSV4RRFFQ69G5FAV') {
      return {'data': {
        'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        'document_number': 'PR-00186', 'status': 'posted',
        'return_date': '2026-11-14',
        'grand_total': '6480.0000',
        'lines': <Map<String, dynamic>>[],
      }};
    }
    if (path == '/api/sales/expenses?per_page=100') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
          'document_number': 'EV-00684',
          'expense_date': '2026-11-14',
          'expense_account': {'name': 'Office Rent'},
          'payment_account': {'name': 'Cash'},
          'status': 'posted', 'amount': '85000.0000',
          'description': 'Monthly rent'},
      ]};
    }
    return {'data': []};
  }
}

void main() {
  late ReferenceStubApi api;
  late AppController app;
  setUp(() {
    api = ReferenceStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'sales.return', 'purchase_returns.view',
      'purchase_returns.create', 'expenses.view',
    ]};
  });
  tearDown(() async => api.close());

  testWidgets('39 Sales Return Entry keeps secured source linked form',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReturnDocumentEditor(
      app: app, kind: ReturnDocumentKind.sale)));
    await tester.pump();
    expect(find.text('Create Sales Return'), findsWidgets);
    expect(find.text('Choose original posted invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('40 Purchase Returns list displays server supplied data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReturnDocumentsScreen(
      app: app, kind: ReturnDocumentKind.purchase)));
    await tester.pumpAndSettle();
    expect(find.text('PR-00186'), findsOneWidget);
    expect(find.text('Authorized supplier'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('41 Purchase Return Entry retains existing draft flow',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReturnDocumentEditor(
      app: app, kind: ReturnDocumentKind.purchase)));
    await tester.pump();
    expect(find.text('Create Purchase Return'), findsWidgets);
    expect(find.text('Choose original posted invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('42 Purchase Return Detail renders posted server status',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReturnDocumentEditor(
      app: app, kind: ReturnDocumentKind.purchase,
      documentUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAV')));
    await tester.pumpAndSettle();
    expect(find.text('Purchase Return Detail'), findsWidgets);
    expect(find.text('PR-00186'), findsOneWidget);
    expect(find.text('Status: posted'), findsWidgets);
    expect(find.text('Review & Post Return'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('43 Expense Vouchers filters loaded API expense rows',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ExpensesScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('Expense Vouchers'), findsWidgets);
    expect(find.text('Office Rent'), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-filter')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('expense-search')), 'missing');
    await tester.pump();
    expect(find.text('No matching expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
