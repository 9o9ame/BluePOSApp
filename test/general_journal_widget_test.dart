import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/general_journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _JournalApi extends BlueposApi {
  final requests = <Map<String, dynamic>>[];
  final paths = <String>[];

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? idempotencyKey}) async {
    paths.add(path);
    requests.add(Map<String, dynamic>.from(body));
    return {
      'entries': const [],
      'has_more': false,
      'totals': {
        'debit': '12.5000',
        'credit': '12.5000',
        'difference': '0.0000',
      },
    };
  }
}

void main() {
  testWidgets('General Journal preview is read-only and uses server totals',
      (tester) async {
    final api = _JournalApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(
      home: GeneralJournalReportScreen(app: app),
    ));
    await tester.pumpAndSettle();
    expect(find.text('PKR 12.50'), findsNWidgets(2));
    expect(api.paths.single,
      '/api/reports/accounting/general-journal/preview');
    expect(api.requests.single['print_format'], 'transaction_wise');
    expect(api.requests.single.containsKey('tenant_id'), isFalse);
    expect(api.requests.single.containsKey('posted_total'), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });

  testWidgets('Unbalanced-only filter is explicitly sent to backend',
      (tester) async {
    final api = _JournalApi();
    final app = AppController(api, AppAppearance());
    await tester.pumpWidget(MaterialApp(
      home: GeneralJournalReportScreen(app: app),
    ));
    await tester.pumpAndSettle();

    expect(api.requests.last['only_problematic'], false);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(api.requests.last['only_problematic'], true);
    expect(api.requests.last['narration'], true);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });
}
