import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/cash_book.dart';

class _CashBookApi extends BlueposApi {
  final requests = <String>[];

  @override
  Future<dynamic> get(String path) async {
    requests.add(path);
    if (path == '/api/reports/accounting/cash-book/accounts') {
      return {
        'accounts': [
          {
            'ulid': '01JAAABBBCCCDDDEEEFFFGGGHH',
            'name': 'Counter Cash', 'is_cash': true, 'is_bank': false,
          },
          {
            'ulid': '01JAAABBBCCCDDDEEEFFFGGGHJ',
            'name': 'Bank', 'is_cash': false, 'is_bank': true,
          },
        ],
      };
    }
    if (path.startsWith('/api/reports/accounting/cash-book?')) {
      return {
        'totals': {
          'opening': '123.4500',
          'received': '20.0000',
          'paid': '5.0000',
          'closing': '138.4500',
        },
        'rows': [
          {
            'line_ulid': '01JAAABBBCCCDDDEEEFFFGGGHK',
            'doc': 'PAYMENT VOUCHER',
            'trans_no': 'PV-20',
            'date': '2026-11-05',
            'description': 'Approved voucher',
            'debit': '0.0000',
            'credit': '5.0000',
            'balance': '138.4500',
          },
        ],
      };
    }
    throw StateError('Unexpected route: $path');
  }
}

void main() {
  testWidgets('Cash Book renders only server-provided financial totals',
      (tester) async {
    final api = _CashBookApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(home: CashBookReportScreen(app: app)));
    await tester.pumpAndSettle();

    expect(find.text('PKR 123.45'), findsOneWidget);
    expect(find.text('PKR 138.45'), findsOneWidget);
    // Transaction rows are lazily rendered further down the report.
    await tester.scrollUntilVisible(find.text('PAYMENT VOUCHER'), 180,
      scrollable: find.byType(Scrollable).first);
    expect(find.text('PAYMENT VOUCHER'), findsOneWidget);
    expect(find.text('PV-20'), findsOneWidget);
    expect(api.requests.any((path) => path.contains('include_bank=0')), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });

  testWidgets('Cash Book includes bank only after explicit toggle',
      (tester) async {
    final api = _CashBookApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(home: CashBookReportScreen(app: app)));
    await tester.pumpAndSettle();

    expect(api.requests.any((path) => path.contains('include_bank=0')), isTrue);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // A bank account must not be requested until the toggle is explicitly on.
    expect(api.requests.any((path) => path.contains('include_bank=1')), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });
}
