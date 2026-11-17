import 'package:bluepos_app/screens/catalog_master.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('16-17 subcategory payload uses authorized parent ULID', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.subcategories,
      name: '  Snacks  ',
      description: '  Packaged snacks  ',
      categoryUlid: '01JAAABBBCCCDDDEEEFFFGGGHH',
      isActive: true,
    );
    expect(payload['name'], 'Snacks');
    expect(payload['description'], 'Packaged snacks');
    expect(payload['category_ulid'], '01JAAABBBCCCDDDEEEFFFGGGHH');
    expect(payload['is_active'], isTrue);
    expect(payload.containsKey('icon'), isFalse);
    expect(payload.containsKey('color'), isFalse);
    expect(payload.containsKey('code'), isFalse);
  });

  test('16-17 invalid parent identifier is never submitted', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.subcategories,
      name: 'Snacks',
      categoryUlid: 'wrong',
      isActive: true,
    );
    expect(payload.containsKey('category_ulid'), isFalse);
  });

  test('18-19 brand visuals and display code remain presentation-only', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.brands,
      name: '  Example Brand  ',
      description: '  Sample  ',
      isActive: false,
    );
    expect(payload['name'], 'Example Brand');
    expect(payload['description'], 'Sample');
    expect(payload['is_active'], isFalse);
    expect(payload.containsKey('icon'), isFalse);
    expect(payload.containsKey('color'), isFalse);
    expect(payload.containsKey('code'), isFalse);
  });

  test('20 unit payload keeps symbol and decimal flag without fake fields', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.units,
      name: '  Piece  ',
      symbol: '  PCS  ',
      allowsDecimal: false,
      isActive: true,
    );
    expect(payload['name'], 'Piece');
    expect(payload['symbol'], 'PCS');
    expect(payload['allows_decimal'], isFalse);
    expect(payload.containsKey('conversion_factor'), isFalse);
    expect(payload.containsKey('description'), isFalse);
  });
}
