import 'package:bluepos_app/screens/transaction_widgets.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Purchase monetary inputs preserve verified 4dp server precision', () {
    expect(validNonNegativeDecimal('0', 4), isTrue);
    expect(validNonNegativeDecimal('123456789.1234', 4), isTrue);
    expect(validNonNegativeDecimal('1.23456', 4), isFalse);
    expect(validNonNegativeDecimal('-1', 4), isFalse);
    expect(validNonNegativeDecimal('2e3', 4), isFalse);
    expect(validNonNegativeDecimal('1,000', 4), isFalse);
    expect(validPositiveDecimal('1.000001', 6), isTrue);
    expect(validPositiveDecimal('0', 6), isFalse);
  });

  testWidgets('Compact metadata grid does not overflow at Android width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var selected = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Expanded(child: BpReferenceCompactField(
            label: 'Invoice Number (server)',
            icon: Icons.receipt_long_outlined,
            value: 'PUR-000002')),
          const SizedBox(width: 7),
          Expanded(child: BpReferenceCompactField(
            label: 'Supplier *', icon: Icons.person_outline,
            value: 'BluePOS Supplier With Long Name',
            onTap: () => selected = true)),
        ]),
      )),
    )));
    await tester.pump();
    expect(find.text('PUR-000002'), findsOneWidget);
    await tester.tap(find.text('BluePOS Supplier With Long Name'));
    await tester.pump();
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shared invoice footer supports blue ledger and disabled Post',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftLabel: 'Print', rightLabel: 'View Ledger',
        rightColor: Color(0xFF006DF6)),
    )));
    final right = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(right.onPressed, isNull);
    expect(right.style?.backgroundColor?.resolve({}),
      const Color(0xFF006DF6));
    expect(tester.takeException(), isNull);
  });

  test('Public API ULIDs reject internal database IDs', () {
    expect(validPublicUlid('123'), isFalse);
    expect(validPublicUlid('1'), isFalse);
    expect(validPublicUlid('01JAAABBBCCCDDDEEEFFFGGGHH'), isTrue);
  });
}
