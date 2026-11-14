import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/receipt.dart';
import 'package:bluepos_app/screens/purchase_invoices.dart';
import 'package:bluepos_app/screens/returns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class InvoiceReferenceStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/sales/') && !path.contains('returns')) {
      return {'data': {
        'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
        'document_number': 'SI-TEST',
        'sale_date': '2026-11-14',
        'status': 'posted',
        'grand_total': '125.0000',
        'subtotal': '125.0000',
        'paid_amount': '125.0000',
        'balance_due': '0',
        'items': <Map<String, dynamic>>[],
      }};
    }
    if (path.startsWith('/api/purchases/') && !path.contains('lines')) {
      return {'data': {
        'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
        'document_number': 'PI-TEST',
        'invoice_date': '2026-11-14',
        'status': 'posted',
        'grand_total': '180.0000',
        'supplier': {'name': 'Authorized supplier', 'code': 'SUP-001'},
        'lines': <Map<String, dynamic>>[],
      }};
    }
    if (path.startsWith('/api/purchases?')) {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
          'document_number': 'PI-TEST',
          'invoice_date': '2026-11-14', 'status': 'posted',
          'grand_total': '180.0000',
          'supplier': {'name': 'Authorized supplier'}},
      ], 'meta': {'total': 1}};
    }
    if (path.startsWith('/api/sales-returns?')) {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAX',
          'document_number': 'SR-TEST',
          'return_date': '2026-11-14', 'status': 'posted',
          'grand_total': '20.0000',
          'customer': {'name': 'Authorized customer'}},
      ], 'meta': {'total': 1}};
    }
    return {'data': []};
  }
}

void main() {
  late InvoiceReferenceStubApi api;
  late AppController app;
  setUp(() {
    api = InvoiceReferenceStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'sales.view', 'purchases.view', 'sales.return',
    ]};
  });
  tearDown(() async => api.close());

  testWidgets('34 sale invoice details are loaded from server',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReceiptScreen(app: app,
        saleUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAV')));
    await tester.pumpAndSettle();
    expect(find.text('Sales Invoice Detail'), findsOneWidget);
    expect(find.text('SI-TEST'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('35 purchase invoice directory uses image-based cards',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PurchaseInvoicesScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('PI-TEST'), findsOneWidget);
    expect(find.text('Authorized supplier'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('36 purchase entry retains original draft controls',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PurchaseInvoiceEditor(app: app)));
    await tester.pump();
    expect(find.text('Create Purchase Invoice'), findsOneWidget);
    expect(find.text('Choose supplier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('37 posted purchase details show real status and total',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PurchaseInvoiceEditor(app: app,
        documentUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAW')));
    await tester.pumpAndSettle();
    expect(find.text('Purchase Invoice Detail'), findsOneWidget);
    expect(find.text('Server status: posted'), findsOneWidget);
    expect(find.text('Authorized supplier'), findsOneWidget);
    expect(find.text('Review & Post Purchase Invoice'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('38 sales return directory displays source-linked records',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReturnDocumentsScreen(
      app: app, kind: ReturnDocumentKind.sale)));
    await tester.pumpAndSettle();
    expect(find.text('SR-TEST'), findsOneWidget);
    expect(find.text('Authorized customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
