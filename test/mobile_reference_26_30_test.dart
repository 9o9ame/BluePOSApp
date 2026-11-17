import 'package:bluepos_app/screens/parties.dart';
import 'package:bluepos_app/screens/customer_detail.dart';
import 'package:bluepos_app/screens/supplier_detail.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('27 party payload keeps server account context and required code', () {
    final payload = partyPayload(
      type: 'customer',
      code: ' cust-100 ',
      name: ' Example Customer ',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true,
      mobile: '03001234567',
      area: 'Karachi',
    );
    expect(payload['code'], 'CUST-100');
    expect(payload['name'], 'Example Customer');
    expect(payload['party_type'], 'customer');
    expect(payload['mobile'], '03001234567');
    expect(payload.containsKey('tenant_id'), isFalse);
    expect(payload.containsKey('opening_balance'), isFalse);
    expect(payload.containsKey('credit_limit'), isFalse);
  });

  test('29 supplier payload does not fabricate payable balance', () {
    final payload = partyPayload(
      type: 'vendor', code: 'SUP-1', name: 'Example Supplier',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true,
    );
    expect(payload['party_type'], 'vendor');
    expect(payload.containsKey('payable_balance'), isFalse);
    expect(payload.containsKey('credit_days'), isFalse);
  });

  test('web-backed customer credit policy preserves NUMERIC precision', () {
    final payload = partyPayload(
      type: 'customer',
      code: 'CUS-100', name: 'Verified Customer',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true,
      email: 'team@example.com',
      creditLimitAmount: '123456789.1234',
      creditLimitDays: '30',
    );
    expect(payload['credit_limit_amount'], '123456789.1234');
    expect(payload['credit_limit_days'], 30);
    expect(payload['email'], 'team@example.com');
    expect(payload.containsKey('balance'), isFalse);
    expect(payload.containsKey('opening_balance'), isFalse);
  });

  test('supplier credit policy is not an invented payable balance', () {
    final payload = partyPayload(
      type: 'vendor',
      code: 'SUP-100', name: 'Verified Supplier',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true,
      creditLimitAmount: '150000.0000',
      creditLimitDays: '45',
    );
    expect(payload['credit_limit_amount'], '150000.0000');
    expect(payload['credit_limit_days'], 45);
    expect(payload.containsKey('payable_balance'), isFalse);
  });

  testWidgets('shared compact field metrics stay centralized', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: BpReferenceFormField(
        label: 'Customer Name *', hint: 'Enter customer name',
        icon: Icons.person_outline_rounded),
    )));
    expect(find.text('Customer Name *'), findsOneWidget);
    expect(BpReferenceMetrics.actionHeight, lessThan(50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('28 customer details use actual supplied server values',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: CustomerDetailView(customer: {
        'name': 'ABC Traders',
        'code': 'CUST-0001',
        'mobile': '03001234567',
      }),
    )));
    await tester.pump();
    expect(find.text('ABC Traders'), findsOneWidget);
    expect(find.text('03001234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('30 supplier details use actual supplied server values',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SupplierDetailView(supplier: {
        'name': 'Verified Supplier',
        'code': 'SUP-0001',
        'area': 'Lahore',
      }),
    )));
    await tester.pump();
    expect(find.text('Verified Supplier'), findsOneWidget);
    expect(find.text('Lahore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
