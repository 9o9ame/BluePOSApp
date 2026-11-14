import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tight IndexedStack sizes a preserved POS column and tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget shell(int index) => MaterialApp(home: Scaffold(
      body: LayoutBuilder(builder: (context, bounds) => SizedBox(
        width: bounds.maxWidth,
        height: bounds.maxHeight,
        child: IndexedStack(sizing: StackFit.expand, index: index, children: [
          const Center(child: Text('Home')),
          Column(children: [
            Expanded(child: ListView(children: const [
              SizedBox(height: 200, child: Text('POS catalog')),
            ])),
            const SizedBox(height: 70, child: Center(child: Text('Cart footer'))),
          ]),
          ListView(children: const [Text('Products')]),
          ListView(children: const [Text('Reports')]),
          ListView(children: const [Text('Modules')]),
        ]),
      )),
    ));

    await tester.pumpWidget(shell(1));
    expect(find.text('POS catalog'), findsOneWidget);
    expect(find.text('Cart footer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(shell(2));
    expect(find.text('Products'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(shell(3));
    expect(find.text('Reports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
