import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/financial_statements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReportsApi extends BlueposApi {
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? idempotencyKey}) async {
    lastPath = path;
    lastBody = body;
    if (path.endsWith('/income-statement/preview')) {
      return <String, dynamic>{
        'net_income': '45.1250',
        'basis': 'posted_ledger',
        'sections': [
          {
            'name': 'Sales Income',
            'class': 'REVENUES',
            'amount': '45.1250',
            'rows': [
              {
                'account': {'name': 'Sales Revenue'},
                'amount': '45.1250',
              },
            ],
          },
        ],
        'limitations': ['Posted ledger balances only'],
      };
    }
    return <String, dynamic>{
      'totals': {
        'debit': '10.5000',
        'credit': '10.5000',
        'difference': '0.0000',
        'difference_side': 'Dr',
      },
      'groups': [],
      'limitations': ['No inventory adjustments are inferred'],
    };
  }
}

void main() {
  testWidgets('Income Statement shows server net income, not a client estimate',
      (tester) async {
    final api = _ReportsApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(
      home: FinancialStatementScreen(
        app: app, kind: FinancialStatementKind.incomeStatement),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PKR 45.13'), findsWidgets);
    expect(api.lastPath, '/api/reports/accounting/income-statement/preview');
    expect(api.lastBody?.containsKey('as_of_date'), isTrue);
    expect(api.lastBody?.containsKey('tenant_id'), isFalse);
    expect(api.lastBody?.containsKey('branch_id'), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });

  testWidgets('Balance Sheet uses posted server debit/credit figures',
      (tester) async {
    final api = _ReportsApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(
      home: FinancialStatementScreen(
        app: app, kind: FinancialStatementKind.balanceSheet),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PKR 10.50'), findsNWidgets(2));
    expect(api.lastPath, '/api/reports/accounting/balance-sheet/preview');
    expect(api.lastBody?['summarized'], isTrue);
    expect(api.lastBody?.containsKey('account_type_ulids'), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });
}
