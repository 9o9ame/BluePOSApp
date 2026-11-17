import 'package:bluepos_app/core/api.dart';
import 'package:bluepos_app/core/appearance.dart';
import 'package:bluepos_app/core/session.dart';
import 'package:bluepos_app/screens/catalog_master.dart';
import 'package:bluepos_app/screens/modules.dart';
import 'package:bluepos_app/screens/product_details.dart';
import 'package:bluepos_app/screens/products.dart';
import 'package:flutter/material.dart';
import 'package:bluepos_app/widgets/reference_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('11 Definition launches approved permission-gated entries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final app = AppController(BlueposApi(), AppAppearance());
    app.session = {
      'permissions': ['products.view', 'categories.view'],
      'entitlements': {'features': ['catalog']},
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModulesScreen(app: app, navigate: (_) {}))));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('menu-Definition')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('approved-definition-home')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Products')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Categories')), findsOneWidget);
    expect(find.byKey(const ValueKey('definition-Units')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await app.api.close();
  });

  testWidgets('12 Products reference card uses authorized row values',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final api = BlueposApi();
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 366,
        child: CatalogProductRow(
          api: api, currency: 'PKR', onTap: () {},
          product: {
            'ulid': '01JAAABBBCCCDDDEEEFFFGGGHH',
            'name': 'Sample Product',
            'sku': 'S-1',
            'prices': [
              {'price_type': 'retail', 'is_active': true,
                'amount': '120.0000'},
            ],
            'sales_lookup': {'in_stock': '168.000000'},
          },
        ))))));
    await tester.pump();
    expect(find.text('Sample Product'), findsOneWidget);
    expect(find.textContaining('Stock: 168'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });

  testWidgets('13 Product Detail hides purchase rate without permission',
      (tester) async {
    final api = BlueposApi();
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ProductDetailsView(
        api: api, currency: 'PKR',
        product: {
          'name': 'Sample Product', 'sku': 'S-1',
          'purchase_rate': '90.0000',
          'prices': [{'price_type': 'retail', 'amount': '120.0000'}],
        },
      ))));
    await tester.pump();
    expect(find.text('Product Detail'), findsNothing);
    expect(find.text('Sample Product'), findsOneWidget);
    expect(find.text('Purchase Price'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await api.close();
  });

  test('15 category payload does not send unsupported visual fields', () {
    final payload = catalogMasterPayload(
      CatalogMasterConfig.categories,
      name: 'Grocery', description: 'Everyday items', isActive: true);
    expect(payload['name'], 'Grocery');
    expect(payload['description'], 'Everyday items');
    expect(payload['is_active'], true);
    expect(payload.containsKey('code'), isFalse);
    expect(payload.containsKey('icon'), isFalse);
    expect(payload.containsKey('color'), isFalse);
  });

  testWidgets('reference header uses the selected theme in both modes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        home: const Scaffold(
          appBar: BpReferenceSubpageAppBar(title: 'Categories'))));
      await tester.pump();
      expect(find.text('Categories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reference palette uses actual inherited theme brightness',
      (tester) async {
    Color? lightInk;
    Color? darkInk;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      home: Builder(builder: (context) {
        lightInk = BpReferenceStyle.of(context).ink;
        return const SizedBox();
      }),
    ));
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(builder: (context) {
        darkInk = BpReferenceStyle.of(context).ink;
        return const SizedBox();
      }),
    ));
    await tester.pump();
    expect(lightInk, isNotNull);
    expect(darkInk, isNotNull);
    expect(lightInk, isNot(darkInk));
  });
}
