import 'package:flutter_test/flutter_test.dart';
import 'package:bluepos_app/screens/catalog_master.dart';
import 'package:bluepos_app/screens/parties.dart';

void main() {
  test('catalog create payload uses server-generated master code', () {
    final data = catalogMasterPayload(CatalogMasterConfig.categories,
      name: ' Bakery ', description: 'Retail category', isActive: true);
    expect(data['name'], 'Bakery');
    expect(data['description'], 'Retail category');
    expect(data['is_active'], isTrue);
    expect(data.containsKey('code'), isFalse);
    expect(data.containsKey('tenant_id'), isFalse);
  });

  test('unit payload retains required symbol and allows_decimal', () {
    final data = catalogMasterPayload(CatalogMasterConfig.units,
      name: 'Kilogram', symbol: 'KG', allowsDecimal: true, isActive: true);
    expect(data['symbol'], 'KG');
    expect(data['allows_decimal'], isTrue);
    expect(data.containsKey('warehouse_id'), isFalse);
  });

  test('subcategory payload references category by ULID only', () {
    final data = catalogMasterPayload(CatalogMasterConfig.subcategories,
      name: 'Food', isActive: true,
      categoryUlid: '01JAAABBBCCCDDDEEEFFFGGGHH');
    expect(data['category_ulid'], '01JAAABBBCCCDDDEEEFFFGGGHH');
    expect(data.containsKey('category_id'), isFalse);
  });

  test('party create payload preserves server-owned accounting boundaries', () {
    final data = partyPayload(
      type: 'customer', code: ' cus-01 ', name: 'Customer One',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true, mobile: '+923000000000');
    expect(data['party_type'], 'customer');
    expect(data['code'], 'CUS-01');
    expect(data['account_type_ulid'], '01JAAABBBCCCDDDEEEFFFGGGHH');
    expect(data.containsKey('tenant_id'), isFalse);
    expect(data.containsKey('account_id'), isFalse);
    expect(data.containsKey('opening_balance'), isFalse);
    expect(data.containsKey('balance'), isFalse);
  });

  test('party payload rejects invalid type and foreign key', () {
    expect(() => partyPayload(
      type: 'unknown', code: 'A', name: 'X',
      accountTypeUlid: '01JAAABBBCCCDDDEEEFFFGGGHH', isActive: true),
      throwsFormatException);
    expect(() => partyPayload(
      type: 'vendor', code: 'A', name: 'X',
      accountTypeUlid: '123', isActive: true),
      throwsFormatException);
  });
}
