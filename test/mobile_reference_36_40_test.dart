import 'package:bluepos_app/screens/returns.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('38 and 40 reference lists keep server-backed endpoints', () {
    expect(ReturnDocumentKind.sale.path, '/api/sales-returns');
    expect(ReturnDocumentKind.purchase.path, '/api/purchase-returns');
    expect(ReturnDocumentKind.sale.sourcePath, '/api/sales');
    expect(ReturnDocumentKind.purchase.sourcePath, '/api/purchases');
  });

  test('39 return lines preserve the source linked ULID request field', () {
    expect(ReturnDocumentKind.sale.sourceKey, 'sale_ulid');
    expect(ReturnDocumentKind.sale.lineKey, 'sale_item_ulid');
    expect(ReturnDocumentKind.purchase.sourceKey, 'purchase_ulid');
    expect(ReturnDocumentKind.purchase.lineKey, 'purchase_line_ulid');
  });

  testWidgets('shared purchase/return footer buttons fit narrow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var drafts = 0;
    var posted = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftKey: const ValueKey('purchase-save-draft'),
        rightKey: const ValueKey('purchase-post'),
        leftLabel: 'Save Draft',
        rightLabel: 'Post Purchase',
        onLeft: () => drafts++,
        onRight: () => posted++,
      ),
    )));
    await tester.pump();
    expect(find.byKey(const ValueKey('purchase-save-draft')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase-post')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('purchase-save-draft')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('purchase-post')));
    await tester.pump();
    expect(drafts, 1);
    expect(posted, 1);
    expect(BpReferenceMetrics.actionHeight, 43);
  });

  testWidgets('Post stays disabled until the server draft has lines',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftLabel: 'Create Draft', rightLabel: 'Post Return'),
    )));
    final actions = tester.widgetList<FilledButton>(
      find.byType(FilledButton)).toList();
    expect(actions, hasLength(1));
    expect(actions.single.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
