import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/screens/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reference 12 row shows only server product data and opens details',
      (tester) async {
    final item = <String, dynamic>{
      'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      'name': 'Authorized Test Product 500 ml',
      'sku': 'T-500',
      'sales_lookup': {'in_stock': '168'},
      'prices': [
        {'price_type': 'retail', 'is_active': true, 'amount': '120.0000'},
      ],
    };
    var opened = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 365, child: CatalogProductRow(
        product: item, api: BlueposApi(), currency: 'Rs',
        onTap: () => opened = true)),
    )));
    expect(find.text('Authorized Test Product 500 ml'), findsOneWidget);
    expect(find.text('SKU: T-500'), findsOneWidget);
    expect(find.text('Stock: 168'), findsOneWidget);
    expect(find.text('Rs 120.00'), findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey('catalog-product-01ARZ3NDEKTSV4RRFFQ69G5FAV')));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference 12 row handles missing price and stock without fakes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 330, child: CatalogProductRow(
        product: const {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
          'name': 'Unpriced item with a longer description',
          'sku': 'T-1'},
        api: BlueposApi(), currency: 'Rs', onTap: () {})),
    )));
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('Stock not shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
