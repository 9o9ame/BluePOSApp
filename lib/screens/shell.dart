import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';
import 'dashboard.dart';
import 'modules.dart';
import 'products.dart';
import 'reports.dart';
import 'sale.dart';
import 'settings.dart';
import 'notifications.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.app});
  final AppController app;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  final saleKey = GlobalKey<SaleScreenState>();
  late final List<Widget> pages = [
    DashboardScreen(app: widget.app, navigate: navigate),
    SaleScreen(key: saleKey, app: widget.app),
    ProductsScreen(app: widget.app, catalogHome: true, onAdd: (product) {
      saleKey.currentState?.addProduct(product);
      navigate(1);
    }),
    ReportsScreen(app: widget.app),
    MoreScreen(app: widget.app, navigate: navigate),
  ];
  static const titles = ['Home', 'POS Sale', 'Products', 'Reports', 'Modules'];
  void navigate(int i) => setState(() => selected = i);

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final reference = selected == 0 || selected == 1 || selected == 4;
    final base = Theme.of(context);
    final refTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF008F65),
        brightness: Brightness.light,
        surface: const Color(0xFFF7F8FF)),
      scaffoldBackgroundColor: const Color(0xFFF7F8FF),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8FF),
        foregroundColor: Color(0xFF081943),
        elevation: 0),
    );
    return Theme(
      data: reference ? refTheme : base,
      child: Builder(builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: reference
              ? const Color(0xFFF7F8FF) : null,
            leadingWidth: 47,
            leading: selected == 1
              ? IconButton(
                  tooltip: 'Back to Home',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => navigate(0))
              : IconButton(
                  tooltip: 'Open Main Menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () {
                    navigate(4);
                  }),
            centerTitle: true,
            titleSpacing: 0,
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              const BlueposBrandMark(size: 36),
              const SizedBox(width: 7),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(const TextSpan(children: [
                    TextSpan(text: 'Blue',
                      style: TextStyle(color: Color(0xFF071947))),
                    TextSpan(text: 'POS',
                      style: TextStyle(color: Color(0xFF079BFA))),
                  ]), style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900)),
                  if (selected == 0 || selected == 4)
                    const Text('P O S  &  E R P',
                      style: TextStyle(fontSize: 7,
                        color: Color(0xFF071947),
                        fontWeight: FontWeight.w700)),
                ]),
            ]),
            actions: [
              IconButton(
                key: const ValueKey('open-notifications'),
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(builder: (_) =>
                    NotificationsScreen(app: app))),
              ),
              if (selected == 1)
                IconButton(
                  tooltip: 'Open product catalog',
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: () => navigate(2)),
              const SizedBox(width: 3),
            ],
          ),
          body: LayoutBuilder(builder: (context, bounds) => SizedBox(
            width: bounds.maxWidth,
            height: bounds.maxHeight,
            child: IndexedStack(
              sizing: StackFit.expand,
              index: selected,
              children: pages,
            ),
          )),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: reference ? Colors.white : Theme.of(ctx).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
                boxShadow: const [BoxShadow(
                  color: Color(0x23527AA4),
                  offset: Offset(0, -3), blurRadius: 15)],
              ),
              child: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: navigate,
                backgroundColor: Colors.transparent,
                indicatorColor: reference
                  ? const Color(0xFF06AA70) : scheme.primary,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
                labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
                height: app.appearance.density == 'compact' ? 62 : 71,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded,
                      color: Colors.white), label: 'Home'),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart_rounded,
                      color: Colors.white), label: 'POS'),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2_rounded,
                      color: Colors.white), label: 'Products'),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded,
                      color: Colors.white), label: 'Reports'),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz_rounded),
                    selectedIcon: Icon(Icons.more_horiz_rounded,
                      color: Colors.white), label: 'More'),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

void openSales(BuildContext context, AppController app) => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => DataListScreen(app: app,
    title: 'Sales invoices', path: '/api/sales?per_page=25',
    nameKey: 'document_number', subtitleKey: 'sale_date',
    amountKey: 'grand_total', detailPrefix: '/api/sales')));

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.app, required this.navigate});
  final AppController app;
  final ValueChanged<int> navigate;

  @override
  Widget build(BuildContext context) =>
      ModulesScreen(app: app, navigate: navigate);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.app});
  final AppController app;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> rows = [];
  bool busy = true; String? error;
  @override
  void initState() {super.initState(); load();}
  Future<void> load() async {
    setState(() {busy = true; error = null;});
    try {
      final warehouse = field(objectOf(widget.app.session?['warehouse'])['ulid']);
      if (warehouse.length != 26) throw const ApiFailure('WAREHOUSE', 'No active warehouse.', 0);
      final response = await widget.app.api.get(Uri(path: '/api/inventory/stock',
        queryParameters: {'warehouse_ulid':warehouse, 'per_page':'50'}).toString());
      if (mounted) setState(() => rows = recordsOf(response));
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(appBar: AppBar(title: const Text('Warehouse Stock'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          GradientHero(appearance: widget.app.appearance, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warehouse_outlined, color: Colors.white, size: 30),
              const SizedBox(height: 12),
              Text(widget.app.warehouseName, style: const TextStyle(color: Colors.white,
                fontSize: 23, fontWeight: FontWeight.w900)),
              const Text('Stock quantities are provided by BluePOS API',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
          const SizedBox(height: 16),
          if (busy) pageLoading() else if (error != null) FailureState(message: error!, retry: load)
          else if (rows.isEmpty) const EmptyState(title: 'No warehouse balances')
          else ...rows.map((balance) {
            final product = objectOf(balance['product']);
            return Padding(padding: const EdgeInsets.only(bottom: 9), child: Surface(
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(
                  color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.inventory_2_outlined, color: scheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(field(product['name']), style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(field(product['product_number']), style: TextStyle(fontSize: 11,
                    color: scheme.onSurfaceVariant)),
                ])),
                Text(field(balance['quantity']), style: const TextStyle(fontWeight: FontWeight.w900)),
              ])));
          }),
        ])));
  }
}
