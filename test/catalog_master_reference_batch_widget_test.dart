import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/catalog_master.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CatalogStubApi extends BlueposApi {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/categories') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV', 'name': 'Beverages',
          'code': 'CAT-001', 'is_active': true},
      ]};
    }
    if (path == '/api/subcategories') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAW',
          'name': 'Soft Drinks', 'code': 'SUB-001', 'is_active': true,
          'category': {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
            'name': 'Beverages'}},
      ]};
    }
    if (path == '/api/brands') {
      return {'data': [
        {'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAX',
          'name': 'Example Brand', 'code': 'BRD-001',
          'is_active': true},
      ]};
    }
    return {'data': []};
  }
}

void main() {
  late CatalogStubApi api;
  late AppController app;

  setUp(() {
    api = CatalogStubApi();
    app = AppController(api, AppAppearance());
    app.session = {'permissions': [
      'categories.view', 'categories.create', 'categories.edit',
      'brands.view', 'brands.create', 'brands.edit',
    ]};
  });
  tearDown(() async => api.close());

  Future<void> open(WidgetTester tester, CatalogMasterConfig config) async {
    await tester.pumpWidget(MaterialApp(
      theme: app.appearance.data(Brightness.light),
      home: CatalogMasterScreen(app: app, config: config),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('14 Categories list is searchable and has status filter',
      (tester) async {
    await open(tester, CatalogMasterConfig.categories);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('Code: CAT-001'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('catalog-status-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('catalog-search')), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No matching records'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('15 Add Category shows full-page form and generated code',
      (tester) async {
    await open(tester, CatalogMasterConfig.categories);
    await tester.tap(find.byKey(const ValueKey('catalog-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Category'), findsWidgets);
    expect(find.text('Automatically generated'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-editor-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-editor-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('16 Subcategories list displays actual parent category',
      (tester) async {
    await open(tester, CatalogMasterConfig.subcategories);
    expect(find.text('Soft Drinks'), findsOneWidget);
    expect(find.text('Parent: Beverages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('17 Add Subcategory requires real parent category',
      (tester) async {
    await open(tester, CatalogMasterConfig.subcategories);
    await tester.tap(find.byKey(const ValueKey('catalog-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add Subcategory'), findsWidgets);
    expect(find.text('Automatically generated'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('18 Brands list shows API brand and permission-gated add',
      (tester) async {
    await open(tester, CatalogMasterConfig.brands);
    expect(find.text('Example Brand'), findsOneWidget);
    expect(find.text('Code: BRD-001'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-add')), findsOneWidget);
    app.session = {'permissions': ['brands.view']};
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, CatalogMasterConfig.brands);
    expect(find.byKey(const ValueKey('catalog-add')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('catalog payload never includes client-generated category code', () {
    final category = catalogMasterPayload(
      CatalogMasterConfig.categories,
      name: ' Beverages ', isActive: true,
      description: 'Drinks');
    expect(category['name'], 'Beverages');
    expect(category.containsKey('code'), isFalse);

    final sub = catalogMasterPayload(
      CatalogMasterConfig.subcategories,
      name: 'Soft Drinks', isActive: true,
      categoryUlid: '01ARZ3NDEKTSV4RRFFQ69G5FAV');
    expect(sub['category_ulid'], '01ARZ3NDEKTSV4RRFFQ69G5FAV');
    expect(sub.containsKey('code'), isFalse);
  });
}
