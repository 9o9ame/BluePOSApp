import 'package:bluepos_app/screens/price_lists.dart';
import 'package:bluepos_app/screens/sale_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('22 Price Lists does not fabricate records', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PriceListsScreen()));
    await tester.pump();
    expect(find.text('Price Lists API not available'), findsOneWidget);
    expect(find.byKey(const ValueKey('price-lists-preview-form')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('23 Add Price List reference has disabled save',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: AddPriceListReferenceScreen()));
    await tester.pump();
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('price-list-save-disabled')));
    expect(save.onPressed, isNull);
    expect(find.text('Price List Name *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('24 Sale Scheme card reflects server values only',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SaleSchemeCard(item: {
        'name': 'Actual Scheme',
        'code': 'SC-004',
        'starts_on': '2026-11-15',
        'ends_on': '2026-11-30',
        'is_active': true,
      }),
    )));
    await tester.pump();
    expect(find.text('Actual Scheme'), findsOneWidget);
    expect(find.text('SC-004'), findsOneWidget);
    expect(find.text('✓ Active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('25 Add Sale Scheme preview does not allow posting',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: AddSaleSchemeReferenceScreen()));
    await tester.pump();
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('sale-scheme-save-disabled')));
    expect(save.onPressed, isNull);
    expect(find.text('Scheme Name *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
