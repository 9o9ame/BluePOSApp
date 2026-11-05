import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/screens/sale.dart';
import 'package:bluepos_app/widgets/common.dart';

void main() {
  test('six server-compatible primary themes and three appearance modes', () {
    final appearance = AppAppearance();
    expect(AppAppearance.palette.length, 6);
    appearance.apply({'theme':'dark', 'primaryTheme':'emerald'}, persist:false);
    expect(appearance.mode, ThemeMode.dark);
    expect(appearance.accent, AppAppearance.palette['emerald']);
    appearance.apply({'theme':'system', 'skin':'advanced'}, persist:false);
    expect(appearance.mode, ThemeMode.system);
    expect(appearance.skin, 'advanced');
  });

  test('display money groups digits without floating-point arithmetic', () {
    expect(money('1234567.2345'), 'Rs 1,234,567.23');
    expect(money('0'), 'Rs 0.00');
  });

  test('sale line sends a product ULID and precise quantity, never tenant ID or totals', () {
    final line = CartLine({
      'ulid':'01JAAABBBCCCDDDEEEFFFGGGHH',
      'name':'Test product',
      'base_unit':{'ulid':'01JZZZYYYXXXWWWVVVUUUTTTSS','symbol':'PCS'},
      'prices':[{'price_type':'retail','amount':'120.0000','is_active':true}],
    });
    line.qty = '2.500000';
    line.discount = '10';
    final payload = line.payload();
    expect(payload['product_ulid'], '01JAAABBBCCCDDDEEEFFFGGGHH');
    expect(payload['quantity'], '2.500000');
    expect(payload['discount_percent'], '10.00000000');
    expect(payload.containsKey('tenant_id'), isFalse);
    expect(payload.containsKey('grand_total'), isFalse);
  });

test('server response helpers never infer tenant ids or totals', () {
  final page = {
    'data': [
      {'ulid': '01JAAABBBCCCDDDEEEFFFGGGHH', 'name': 'Authorized product'},
    ],
    'meta': {'total': 1},
  };
  final rows = recordsOf(page);
  expect(rows.length, 1);
  expect(rows.first['name'], 'Authorized product');
  expect(rows.first.containsKey('tenant_id'), isFalse);
});

}
