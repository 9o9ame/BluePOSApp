import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/screens/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('07 POS grid card fits two-line names and stock without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final api = BlueposApi();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(
        width: 185, height: 214,
        child: PosCatalogProductCard(
          api: api, currency: 'PKR', imageFirst: true,
          onTap: () {},
          product: {
            'ulid': '01JAAABBBCCCDDDEEEFFFGGGHH',
            'name': 'BAKING SODA MOTHER CHOICE 100 GRAMS',
            'image_url': '',
            'prices': [
              {'price_type': 'retail', 'is_active': true,
                'amount': '140.0000'},
            ],
            'sales_lookup': {'in_stock': '25.000000'},
          },
        ),
      ))),
    ));
    await tester.pump();
    expect(find.textContaining('BAKING SODA'), findsOneWidget);
    expect(find.textContaining('Rs 140'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });
}
