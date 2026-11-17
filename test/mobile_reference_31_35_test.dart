import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Customer/Supplier details share a compact two-action footer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var edited = 0;
    var ledgers = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(bottomNavigationBar: BpReferenceDetailActions(
        editKey: const ValueKey('customer-detail-edit'),
        ledgerKey: const ValueKey('customer-detail-view-ledger'),
        onEdit: () => edited++,
        onViewLedger: () => ledgers++,
      )),
    ));
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('View Ledger'), findsOneWidget);
    expect(find.byKey(const ValueKey('customer-detail-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('customer-detail-view-ledger')),
        findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('View Ledger'));
    await tester.pump();
    expect(edited, 1);
    expect(ledgers, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit is disabled without edit permission while ledger remains',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(bottomNavigationBar: BpReferenceDetailActions(
        onViewLedger: () {},
      )),
    ));
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Edit'));
    expect(button.onPressed, isNull);
    expect(find.text('View Ledger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Reference footer follows shared compact action size', () {
    expect(BpReferenceMetrics.actionHeight, 43);
    expect(BpReferenceMetrics.actionRadius, 13);
  });
}
