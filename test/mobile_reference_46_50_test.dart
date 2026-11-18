import 'package:bluepos_app/screens/vouchers.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('46 journal voucher is its real server-backed voucher type', () {
    expect(VoucherKind.journal.apiName, 'journal');
    expect(VoucherKind.journal.hasHeader, isFalse);
    expect(VoucherKind.journal.label, 'Journal Voucher');
  });

  test('47-50 payment/receipt are header-based voucher types', () {
    expect(VoucherKind.payment.apiName, 'payment');
    expect(VoucherKind.receiving.apiName, 'receiving');
    expect(VoucherKind.payment.hasHeader, isTrue);
    expect(VoucherKind.receiving.hasHeader, isTrue);
    expect(VoucherKind.payment.label, 'Payment Voucher');
    expect(VoucherKind.receiving.label, 'Receiving Voucher');
  });

  test('voucher line payload keeps decimal strings and public account ULID', () {
    final account = {
      'ulid': '01JAAABBBCCCDDDEEEFFFGGGHH',
      'name': 'Bank Account',
      'code': '1010',
    };
    final line = VoucherRowDraft(
      account: account, amount: '45.1200',
      debit: '45.1200', credit: '0',
      narration: 'Bank payment',
    );
    expect(line.payload(VoucherKind.payment)['amount'], '45.1200');
    expect(line.payload(VoucherKind.receiving)['account_ulid'],
      account['ulid']);
    expect(line.payload(VoucherKind.journal)['debit'], '45.1200');
    expect(line.payload(VoucherKind.journal).containsKey('amount'), isFalse);
    expect(line.payload(VoucherKind.payment).containsKey('debit'), isFalse);
  });

  testWidgets('reference fields share a compact grouped panel at 360px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var picked = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BpReferenceInlinePanel(children: [
            BpReferenceInlineRow(
              label: 'Voucher Number',
              icon: Icons.receipt_long_outlined,
              child: const Text('Assigned by server')),
            BpReferenceInlineRow(
              label: 'Cash / Bank Account',
              icon: Icons.account_balance_wallet_outlined,
              requiredField: true,
              child: TextButton(
                onPressed: () => picked++,
                child: const Text('Choose account'))),
            const BpReferenceInlineRow(
              label: 'Amount',
              icon: Icons.payments_outlined,
              requiredField: true,
              child: Text('0.0000')),
          ]),
        ],
      ),
    )));
    await tester.pump();
    expect(find.byType(BpReferenceInlinePanel), findsOneWidget);
    expect(find.byType(BpReferenceInlineRow), findsNWidgets(3));
    expect(tester.getSize(find.byType(BpReferenceInlinePanel)).height,
      lessThan(200));
    await tester.tap(find.text('Choose account'));
    await tester.pump();
    expect(picked, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voucher footer fits a narrow Android display',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var saved = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftKey: const ValueKey('voucher-save-draft'),
        rightKey: const ValueKey('voucher-post'),
        leftLabel: 'Save Draft',
        rightLabel: 'Post Receipt',
        onLeft: () => saved++,
        onRight: null,
      ),
    )));
    expect(find.byKey(const ValueKey('voucher-save-draft')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('voucher-post')),
      findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('voucher-save-draft')));
    await tester.pump();
    expect(saved, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton))
      .onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
