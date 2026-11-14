import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/screens/product_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = <String, dynamic>{
    'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
    'name': 'Authorized Example Product 500ml',
    'sku': 'EX-500',
    'is_active': true,
    'category': {'name': 'Beverages'},
    'brand': {'name': 'Example Brand'},
    'base_unit': {'name': 'Bottle'},
    'primary_barcode': '123456789012',
    'description': 'Test product description',
    'purchase_rate': '95.0000',
    'reorder_level': '50.000000',
    'prices': [
      {'price_type': 'retail', 'amount': '120.0000', 'is_active': true},
    ],
    'sales_lookup': {'in_stock': '168.000000'},
  };

  testWidgets('Product Detail displays server returned fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ProductDetailsView(
        product: item, api: BlueposApi(), currency: 'Rs',
        canViewPurchaseRate: true),
    )));
    expect(find.text('Authorized Example Product 500ml'), findsOneWidget);
    expect(find.text('SKU: EX-500'), findsOneWidget);
    expect(find.text('Stock: 168.000000'), findsOneWidget);
    expect(find.text('Rs 120.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Details hide purchase cost and edit without permission',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ProductDetailsView(
        product: item, api: BlueposApi(), currency: 'Rs',
        canEdit: false, canViewPurchaseRate: false),
    )));
    expect(find.text('Purchase Price'), findsNothing);
    expect(find.byKey(const ValueKey('product-detail-edit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Details show missing server values as unavailable',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ProductDetailsView(
        product: const {'name': 'Unpriced item'},
        api: BlueposApi(), currency: 'Rs'),
    )));
    expect(find.text('Price unavailable'), findsWidgets);
    expect(find.text('Stock not shown'), findsWidgets);
    expect(find.text('Not available'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Authorized edit action invokes existing editor callback',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ProductDetailsView(
        product: item, api: BlueposApi(), currency: 'Rs',
        canEdit: true, onEdit: () => tapped = true),
    )));
    // ListView builds children lazily: scroll until the footer is mounted.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('product-detail-edit')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('product-detail-edit')));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
