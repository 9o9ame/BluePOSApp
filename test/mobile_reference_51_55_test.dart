import 'package:bluepos_app/screens/delivery_challans.dart';
import 'package:bluepos_app/screens/inventory_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('54-55 opening-stock route and permissions follow web contract', () {
    expect(InventoryDocumentKind.opening.path,
      '/api/inventory/opening-balances');
    expect(InventoryDocumentKind.opening.dateField, 'document_date');
    expect(InventoryDocumentKind.opening.createPermission,
      'inventory.opening_balance.create');
    expect(InventoryDocumentKind.opening.postPermission,
      'inventory.opening_balance.post');
  });

  test('51-53 challan has no invented server contract', () {
    expect(DeliveryChallanReferencePage.values.length, 3);
    expect(DeliveryChallanReferenceScreen.contractNote,
      contains('no document can be saved'));
  });

  testWidgets('51-53 previews do not expose working save or dispatch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: DeliveryChallanReferenceScreen(
        page: DeliveryChallanReferencePage.form)));
    await tester.pumpAndSettle();
    expect(find.text('Create Delivery Challan'), findsOneWidget);
    expect(find.text('Dispatch Unavailable'), findsOneWidget);
    final buttons = tester.widgetList<FilledButton>(
      find.byType(FilledButton));
    expect(buttons.any((button) => button.onPressed != null), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('51 challan preview navigates to form safely',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: DeliveryChallanReferenceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No delivery challans'), findsOneWidget);
    await tester.tap(find.text('Add Challan'));
    await tester.pumpAndSettle();
    expect(find.text('Create Delivery Challan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
