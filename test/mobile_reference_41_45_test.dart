import 'package:bluepos_app/screens/money_actions.dart';
import 'package:bluepos_app/screens/returns.dart';
import 'package:bluepos_app/screens/transaction_widgets.dart';
import 'package:bluepos_app/screens/vouchers.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('41/42 purchase return uses real source-linked server actions', () {
    expect(ReturnDocumentKind.purchase.path, '/api/purchase-returns');
    expect(ReturnDocumentKind.purchase.sourceKey, 'purchase_ulid');
    expect(ReturnDocumentKind.purchase.lineKey, 'purchase_line_ulid');
    expect(ReturnDocumentKind.purchase.postPermission,
        'purchase_returns.post');
  });

  test('43/44 expense uses direct posted API, no invented draft endpoint', () {
    expect(MoneyActionKind.expense.endpoint(''), '/api/sales/expenses');
    expect(MoneyActionKind.expense.requiredPermission, 'expenses.create');
    expect(validPositiveDecimal('123.1234', 4), isTrue);
    expect(validPositiveDecimal('123.12345', 4), isFalse);
    expect(validPositiveDecimal('0', 4), isFalse);
  });

  test('45 journal vouchers remain their own server voucher type', () {
    expect(VoucherKind.journal.apiName, 'journal');
    expect(VoucherKind.journal.hasHeader, isFalse);
    expect(VoucherKind.payment.hasHeader, isTrue);
  });

  testWidgets('compact account and financial inputs fit mobile width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final amount = TextEditingController();
    addTearDown(amount.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          BpReferenceCompactField(
            label: 'Expense Head / Account *',
            icon: Icons.account_balance_outlined,
            value: 'Server-provided account name'),
          BpReferenceCompactField(
            label: 'Amount *',
            icon: Icons.payments_outlined,
            controller: amount, hint: '0.0000'),
        ]),
      ),
    )));
    expect(find.text('Server-provided account name'), findsOneWidget);
    expect(find.text('Amount *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expense post action remains disabled without permission',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftLabel: 'Cancel', rightLabel: 'Confirm Expense',
        rightIcon: Icons.check_circle_outline_rounded),
    )));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(BpReferenceMetrics.actionHeight, 43);
    expect(tester.takeException(), isNull);
  });
}
