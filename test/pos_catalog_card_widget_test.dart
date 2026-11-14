import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/screens/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('POS catalog card selects only the real supplied product',
      (tester) async {
    final product = <String, dynamic>{
      'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      'name': 'Test catalog item',
      'prices': [
        {'price_type': 'retail', 'amount': '123.5000', 'is_active': true},
      ],
      'sales_lookup': {'in_stock': '12.000000'},
    };
    Map<String, dynamic>? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 190, height: 194,
        child: PosCatalogProductCard(
          product: product, api: BlueposApi(), currency: 'Rs',
          onTap: () => selected = product)),
    )));
    expect(find.text('Test catalog item'), findsOneWidget);
    expect(find.textContaining('123.50'), findsOneWidget);
    expect(find.text('Stock: 12.000000'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pos-product-01ARZ3NDEKTSV4RRFFQ69G5FAV')));
    expect(identical(selected, product), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('POS catalog card does not fabricate missing prices or stock',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 190, height: 194,
        child: PosCatalogProductCard(
          product: const {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV', 'name': 'Unpriced item'},
          api: BlueposApi(), currency: 'Rs', onTap: null)),
    )));
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('Stock not shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
