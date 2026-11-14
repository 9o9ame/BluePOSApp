import 'package:bluepos_app/screens/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final notice = <String, dynamic>{
    'ulid': '01ARZ3NDEKTSV4RRFFQ69G5FAV',
    'kind': 'requested',
    'device_name': 'Registered Test Device',
    'username': 'Demo Team Member',
    'created_at': '2026-11-14T10:00:00Z',
    'read_at': null,
  };

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: child));

  testWidgets('renders only actual supplied device alerts and read callback',
      (tester) async {
    Map<String, dynamic>? read;
    await tester.pumpWidget(wrap(NotificationsView(
      notices: [notice], unread: 1, busy: false, error: null,
      selectedTab: 0, onTabChanged: (_) {},
      onRead: (value) => read = value,
    )));
    expect(find.text('Registered Test Device · Demo Team Member'),
      findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.textContaining('Purchase invoice posted'), findsNothing);
    await tester.tap(find.byKey(
      const ValueKey('read-01ARZ3NDEKTSV4RRFFQ69G5FAV')));
    expect(identical(read, notice), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity tab clearly states feed is not available',
      (tester) async {
    await tester.pumpWidget(wrap(NotificationsView(
      notices: [notice], unread: 0, busy: false, error: null,
      selectedTab: 2, onTabChanged: (_) {}, onRead: (_) {},
    )));
    expect(find.text('Activity feed not available'), findsOneWidget);
    expect(find.text('Registered Test Device · Demo Team Member'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner-only error does not leak any notification data',
      (tester) async {
    await tester.pumpWidget(wrap(NotificationsView(
      notices: const [], unread: 0, busy: false,
      error: 'Device notifications are available to tenant owners only.',
      selectedTab: 0, onTabChanged: (_) {}, onRead: (_) {},
    )));
    expect(find.textContaining('tenant owners only'), findsOneWidget);
    expect(find.text('Registered Test Device · Demo Team Member'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alerts filter signals selected category', (tester) async {
    int? chosen;
    await tester.pumpWidget(wrap(NotificationsView(
      notices: const [], unread: 0, busy: false, error: null,
      selectedTab: 0, onTabChanged: (value) => chosen = value,
      onRead: (_) {},
    )));
    await tester.tap(find.text('Alerts'));
    expect(chosen, 1);
    expect(tester.takeException(), isNull);
  });
}
