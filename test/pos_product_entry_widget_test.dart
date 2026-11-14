import 'package:bluepos_app/screens/sale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('POS search and scan call only their existing callbacks',
      (tester) async {
    var searches = 0;
    var scans = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: PosProductEntry(
        onSearch: () => searches++,
        onScan: () => scans++,
      ),
    )));

    expect(find.text('Search products or barcode'), findsOneWidget);
    expect(find.byTooltip('Scan barcode'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pos-search-products')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pos-scan-barcode')));
    await tester.pump();
    expect(searches, 1);
    expect(scans, 1);
  });

  testWidgets('POS entry disables search and scan for unconfirmed sale',
      (tester) async {
    var actions = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: PosProductEntry(
        enabled: false,
        onSearch: () => actions++,
        onScan: () => actions++,
      ),
    )));
    final search = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('pos-search-products')));
    final scan = tester.widget<IconButton>(
      find.byKey(const ValueKey('pos-scan-barcode')));
    expect(search.onPressed, isNull);
    expect(scan.onPressed, isNull);
    expect(actions, 0);
  });
}
