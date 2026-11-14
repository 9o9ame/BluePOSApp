import 'package:bluepos_app/core/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BluePOS themed button fits inside POS cart footer Row',
      (tester) async {
    final appearance = AppAppearance();
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: appearance.data(Brightness.light),
      home: Scaffold(body: Column(children: [
        const Expanded(child: Center(child: Text('POS catalog'))),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            const Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Cart total'), Text('Rs 123.50')])),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {},
              child: const Text('Proceed to Payment'),
            ),
          ]),
        ),
      ])),
    ));

    expect(find.text('Proceed to Payment'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).width, lessThan(390));
  });

  testWidgets('BluePOS themed elevated and filled buttons both fit Rows',
      (tester) async {
    final appearance = AppAppearance();
    await tester.pumpWidget(MaterialApp(
      theme: appearance.data(Brightness.light),
      home: Scaffold(body: Center(child: SizedBox(
        width: 340,
        child: Row(children: [
          ElevatedButton(onPressed: () {}, child: const Text('Next')),
          const SizedBox(width: 10),
          FilledButton(onPressed: () {}, child: const Text('Confirm')),
        ]),
      ))),
    ));
    expect(tester.takeException(), isNull);
  });
}
