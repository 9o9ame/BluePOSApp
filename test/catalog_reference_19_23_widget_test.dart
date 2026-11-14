import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/catalog_master.dart';
import 'package:bluepos_app/screens/price_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MasterStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/brands') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
          'name': 'Verified Brand', 'code': 'BRD-001',
          'is_active': true},
      ]};
    }
    if (path == '/api/units') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
          'name': 'Kilogram', 'code': 'UNT-004',
          'symbol': 'KG', 'allows_decimal': true,
          'is_active': true},
      ]};
    }
    return {'data': []};
  }
}

void main() {
  late MasterStubApi api;
  late AppController app;

  setUp(() {
    api = MasterStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'brands.view', 'brands.create', 'brands.edit',
      'units.view', 'units.create', 'units.edit',
    ]};
  });
  tearDown(() async => api.close());

  Future<void> openMaster(WidgetTester tester, CatalogMasterConfig config) async {
    await tester.pumpWidget(MaterialApp(
      theme: app.appearance.data(Brightness.light),
      home: CatalogMasterScreen(app: app, config: config)));
    await tester.pumpAndSettle();
  }

  testWidgets('19 Add Brand opens actual full-page form with read-only code',
      (tester) async {
    await openMaster(tester, CatalogMasterConfig.brands);
    await tester.tap(find.byKey(const ValueKey('catalog-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Brand'), findsWidgets);
    expect(find.text('Automatically generated'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-editor-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-editor-status')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('20 Units displays actual unit name and short symbol',
      (tester) async {
    await openMaster(tester, CatalogMasterConfig.units);
    expect(find.text('Kilogram'), findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('21 Add Unit keeps server-supported symbol and decimal setting',
      (tester) async {
    await openMaster(tester, CatalogMasterConfig.units);
    await tester.tap(find.byKey(const ValueKey('catalog-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Unit'), findsWidgets);
    expect(find.byKey(const ValueKey('catalog-editor-unit-symbol')), findsOneWidget);
    expect(find.textContaining('conversion factor is not supported'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-editor-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('22 Price Lists never fabricates API records or active price',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PriceListsScreen()));
    expect(find.text('Price Lists integration pending'), findsOneWidget);
    expect(find.text('Retail Price'), findsNothing);
    expect(find.byKey(const ValueKey('price-lists-preview-form')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('23 Add Price List has disabled Save; no fake server write',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AddPriceListReferenceScreen()));
    expect(find.text('Add Price List'), findsOneWidget);
    expect(find.text('Save Price List'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Price List'));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  test('Unit payload excludes unverified conversion factor', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.units, name: 'Kilogram',
      symbol: 'KG', allowsDecimal: true, isActive: true);
    expect(payload['symbol'], 'KG');
    expect(payload['allows_decimal'], isTrue);
    expect(payload.containsKey('base_conversion_factor'), isFalse);
    expect(payload.containsKey('code'), isFalse);
  });
}
